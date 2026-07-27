import 'package:komorebi/src/models/api/crawler_config.dart';
import 'package:komorebi/src/core/services/title_parser_service.dart';
import 'package:quiver/strings.dart';

/// Configurable scoring weights and constants for [SearchRanker].
class RankScoringConfig {
  final double titleSimilarityWeight;
  final double titleSubstringBonus;
  final double seasonMatchBonus;
  final double seasonMismatchPenalty;
  final double episodeMatchBonus;
  final double episodeMismatchPenalty;
  final double resolutionBonus4K;
  final double resolutionBonus1080p;
  final double resolutionBonus720p;
  final double resolutionBonus480p;
  final double maxPopularityBonus;
  final double popularityScaleFactor;
  final int defaultUnrankedConfigIndex;

  const RankScoringConfig({
    this.titleSimilarityWeight = 50.0,
    this.titleSubstringBonus = 20.0,
    this.seasonMatchBonus = 20.0,
    this.seasonMismatchPenalty = 15.0,
    this.episodeMatchBonus = 25.0,
    this.episodeMismatchPenalty = 20.0,
    this.resolutionBonus4K = 10.0,
    this.resolutionBonus1080p = 10.0,
    this.resolutionBonus720p = 7.0,
    this.resolutionBonus480p = 3.0,
    this.maxPopularityBonus = 10.0,
    this.popularityScaleFactor = 50.0,
    this.defaultUnrankedConfigIndex = 999,
  });
}

class SearchRanker {
  /// Default scoring configuration instance.
  static const defaultConfig = RankScoringConfig();

  /// Ranks search results according to query relevance, parsed metadata, popularity,
  /// and config declaration priority.
  static Future<List<CrawlerResult>> rankResults({
    required String query,
    required List<CrawlerResult> results,
    required List<CrawlerConfig> configs,
    RankScoringConfig scoringConfig = defaultConfig,
  }) async {
    if (results.isEmpty || isBlank(query)) return [];

    final configOrder = <String, int>{};
    for (int i = 0; i < configs.length; i++) {
      configOrder[configs[i].id] = i;
    }

    final queryInfo = await _parseQuery(query);

    final scoredItems = results.map((result) {
      final score = _calculateScore(queryInfo, result, scoringConfig);
      final cfgIndex =
          configOrder[result.source] ??
          scoringConfig.defaultUnrankedConfigIndex;
      return _ScoredResult(result: result, score: score, configIndex: cfgIndex);
    }).toList();

    // Sort descending by score, then ascending by configIndex (earlier config first)
    scoredItems.sort((a, b) {
      final scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) return scoreCmp;
      return a.configIndex.compareTo(b.configIndex);
    });

    // Deduplicate items with identical score and raw title, keeping the one from the earlier declared config
    final finalResults = <CrawlerResult>[];
    final seenKey = <String>{};

    for (final item in scoredItems) {
      final key = "${item.score}_${item.result.title.trim()}";
      if (!seenKey.contains(key)) {
        seenKey.add(key);
        finalResults.add(item.result);
      }
    }

    return finalResults;
  }

  static Future<_QueryInfo> _parseQuery(String rawQuery) async {
    final clean = rawQuery.trim();
    final parsed = await TitleParserService.instance.parseTitle(clean);

    String titleQuery = clean;
    String? season;
    String? episode;

    if (parsed != null) {
      if (parsed.title != null && parsed.title!.isNotEmpty) {
        titleQuery = parsed.title!.join(' ');
      }
      if (parsed.season != null && parsed.season!.isNotEmpty) {
        season = parsed.season!.first;
      }
      if (parsed.episode != null && parsed.episode!.isNotEmpty) {
        episode = parsed.episode!.first;
      }
    }

    season ??= RegExp(
      r'\b(?:S|Season)\s*0*(\d+)\b',
      caseSensitive: false,
    ).firstMatch(clean)?.group(1);

    episode ??= RegExp(
      r'\b(?:E|Episode|Ep)\s*0*(\d+)\b',
      caseSensitive: false,
    ).firstMatch(clean)?.group(1);

    return _QueryInfo(
      raw: clean,
      title: titleQuery,
      season: season,
      episode: episode,
    );
  }

  static double _calculateScore(
    _QueryInfo query,
    CrawlerResult result,
    RankScoringConfig cfg,
  ) {
    final parsed = result.parsedTitle;

    if (parsed == null) {
      return result.popularity;
    }

    double score = 0.0;

    // 1. Title similarity
    final candTitle = parsed.title?.join(' ') ?? result.title;
    final similarity = _computeJaccard(query.title, candTitle);
    score += similarity * cfg.titleSimilarityWeight;

    if (candTitle.toLowerCase().contains(query.title.toLowerCase())) {
      score += cfg.titleSubstringBonus;
    }

    // 2. Season match
    if (query.season != null) {
      final candSeasons = parsed.season ?? [];
      bool seasonMatched = false;
      for (final s in candSeasons) {
        if (_intEquals(s, query.season!)) {
          seasonMatched = true;
          break;
        }
      }
      if (seasonMatched) {
        score += cfg.seasonMatchBonus;
      } else if (candSeasons.isNotEmpty) {
        score -= cfg.seasonMismatchPenalty;
      }
    }

    // 3. Episode match
    if (query.episode != null) {
      final candEpisodes = parsed.episode ?? [];
      bool epMatched = false;
      for (final e in candEpisodes) {
        if (_intEquals(e, query.episode!)) {
          epMatched = true;
          break;
        }
      }
      if (epMatched) {
        score += cfg.episodeMatchBonus;
      } else if (candEpisodes.isNotEmpty) {
        score -= cfg.episodeMismatchPenalty;
      }
    }

    // 4. Resolution score
    final res = parsed.videoResolution?.join(' ') ?? '';
    final resLower = res.toLowerCase();
    if (resLower.contains('2160') || resLower.contains('4k')) {
      score += cfg.resolutionBonus4K;
    } else if (resLower.contains('1080')) {
      score += cfg.resolutionBonus1080p;
    } else if (resLower.contains('720')) {
      score += cfg.resolutionBonus720p;
    } else if (resLower.contains('480')) {
      score += cfg.resolutionBonus480p;
    }

    // 5. Popularity bonus
    final popBonus = (result.popularity / cfg.popularityScaleFactor).clamp(
      0.0,
      cfg.maxPopularityBonus,
    );
    score += popBonus;

    return score;
  }

  static double _computeJaccard(String a, String b) {
    final tokensA = _tokenize(a);
    final tokensB = _tokenize(b);
    if (tokensA.isEmpty || tokensB.isEmpty) return 0.0;

    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;

    return union == 0 ? 0.0 : intersection / union;
  }

  static Set<String> _tokenize(String str) {
    return str
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toSet();
  }

  static bool _intEquals(String a, String b) {
    final intA = int.tryParse(a);
    final intB = int.tryParse(b);
    if (intA != null && intB != null) {
      return intA == intB;
    }
    return a.trim() == b.trim();
  }
}

class _QueryInfo {
  final String raw;
  final String title;
  final String? season;
  final String? episode;

  _QueryInfo({
    required this.raw,
    required this.title,
    this.season,
    this.episode,
  });
}

class _ScoredResult {
  final CrawlerResult result;
  final double score;
  final int configIndex;

  _ScoredResult({
    required this.result,
    required this.score,
    required this.configIndex,
  });
}
