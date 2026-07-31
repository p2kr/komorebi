import 'package:freezed_annotation/freezed_annotation.dart';

part 'crawler_config.freezed.dart';
part 'crawler_config.g.dart';

@freezed
abstract class CrawlerConfig with _$CrawlerConfig {
  const factory CrawlerConfig({
    required String id,
    required String name,
    required String baseUrl,
    required String itemSelector,
    required String titleSelector,
    required String linkSelector,
    String? popularitySelector,
    String? sizeSelector,
    required bool isActive,
  }) = _CrawlerConfig;

  factory CrawlerConfig.fromJson(Map<String, dynamic> json) =>
      _$CrawlerConfigFromJson(json);
}

@freezed
abstract class CrawlerResult with _$CrawlerResult {
  const factory CrawlerResult({
    required String title,
    required String link,
    required String source,
    @Default(0) double popularity,
    String? size,
    @JsonKey(includeFromJson: false) CrawlerParsedTitle? parsedTitle,
  }) = _CrawlerResult;

  factory CrawlerResult.fromJson(Map<String, dynamic> json) =>
      _$CrawlerResultFromJson(json);
}

@freezed
abstract class CrawlerParsedTitle with _$CrawlerParsedTitle {
  @StringOrListConverter()
  const factory CrawlerParsedTitle({
    List<String>? audioTerm,
    List<String>? device,
    List<String>? episode,
    List<String>? episodeTitle,
    List<String>? fileChecksum,
    List<String>? fileExtension,
    List<String>? language,
    List<String>? other,
    List<String>? part,
    List<String>? releaseGroup,
    List<String>? releaseInformation,
    List<String>? releaseVersion,
    List<String>? season,
    List<String>? source,
    List<String>? subtitles,
    List<String>? title,
    List<String>? type,
    List<String>? videoResolution,
    List<String>? videoTerm,
    List<String>? volume,
    List<String>? year,
  }) = _CrawlerParsedTitle;

  factory CrawlerParsedTitle.fromJson(Map<String, dynamic> json) =>
      _$CrawlerParsedTitleFromJson(json);
}

/// "str | list[str]" equivalent
class StringOrListConverter implements JsonConverter<List<String>?, Object?> {
  const StringOrListConverter();

  @override
  List<String>? fromJson(Object? json) {
    if (json == null) return null;
    if (json is String) return [json];
    if (json is List) return json.map((e) => e.toString()).toList();

    // Fallback for unexpected types (like numbers)
    return [json.toString()];
  }

  @override
  Object? toJson(List<String>? list) {
    if (list == null || list.isEmpty) return null;
    if (list.length == 1) return list.first;
    return list;
  }
}
