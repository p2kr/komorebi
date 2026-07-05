// Helper parsing methods to avoid any use of 'dynamic' and ensure type safety.

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

bool? _parseBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return null;
}

String? _parseString(Object? value) {
  if (value == null) return null;
  return value.toString();
}

List<T>? _parseList<T>(Object? value, T Function(Object? item) parser) {
  if (value == null || value is! List) return null;
  return value.map(parser).toList();
}

/// Converts an arbitrary Object (usually from JSON decoding) into a type-safe Map.
Map<String, Object?> asMap(Object? json) {
  if (json is Map) {
    return json.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, Object?>{};
}

// =============================================================================
// Paging & Common Models
// =============================================================================

class MalPaging {
  final String? previous;
  final String? next;

  MalPaging({this.previous, this.next});

  factory MalPaging.fromMap(Map<String, Object?> map) {
    return MalPaging(
      previous: _parseString(map['previous']),
      next: _parseString(map['next']),
    );
  }
}

class MalPicture {
  final String? medium;
  final String? large;

  MalPicture({this.medium, this.large});

  factory MalPicture.fromMap(Map<String, Object?> map) {
    return MalPicture(
      medium: _parseString(map['medium']),
      large: _parseString(map['large']),
    );
  }
}

class MalAlternativeTitles {
  final List<String> synonyms;
  final String? en;
  final String? ja;

  MalAlternativeTitles({required this.synonyms, this.en, this.ja});

  factory MalAlternativeTitles.fromMap(Map<String, Object?> map) {
    return MalAlternativeTitles(
      synonyms: _parseList(map['synonyms'], (i) => _parseString(i) ?? '') ?? [],
      en: _parseString(map['en']),
      ja: _parseString(map['ja']),
    );
  }
}

class MalNamedNode {
  final int id;
  final String name;

  MalNamedNode({required this.id, required this.name});

  factory MalNamedNode.fromMap(Map<String, Object?> map) {
    return MalNamedNode(
      id: _parseInt(map['id']) ?? 0,
      name: _parseString(map['name']) ?? '',
    );
  }
}

class MalAuthor {
  final MalNamedNode node;
  final String? role;

  MalAuthor({required this.node, this.role});

  factory MalAuthor.fromMap(Map<String, Object?> map) {
    return MalAuthor(
      node: MalNamedNode.fromMap(asMap(map['node'])),
      role: _parseString(map['role']),
    );
  }
}

class MalBroadcast {
  final String? dayOfTheWeek;
  final String? startTime;

  MalBroadcast({this.dayOfTheWeek, this.startTime});

  factory MalBroadcast.fromMap(Map<String, Object?> map) {
    return MalBroadcast(
      dayOfTheWeek: _parseString(map['day_of_the_week']),
      startTime: _parseString(map['start_time']),
    );
  }
}

class MalSeason {
  final int? year;
  final String? season;

  MalSeason({this.year, this.season});

  factory MalSeason.fromMap(Map<String, Object?> map) {
    return MalSeason(
      year: _parseInt(map['year']),
      season: _parseString(map['season']),
    );
  }
}

class MalRanking {
  final int rank;
  final int? previousRank;

  MalRanking({required this.rank, this.previousRank});

  factory MalRanking.fromMap(Map<String, Object?> map) {
    return MalRanking(
      rank: _parseInt(map['rank']) ?? 0,
      previousRank: _parseInt(map['previous_rank']),
    );
  }
}

// =============================================================================
// User & List Status Models
// =============================================================================

class MalUser {
  final int id;
  final String name;
  final String? picture;
  final String? gender;
  final String? birthday;
  final String? location;
  final String? joinedAt;
  final String? timeZone;
  final bool? isSupporter;

  MalUser({
    required this.id,
    required this.name,
    this.picture,
    this.gender,
    this.birthday,
    this.location,
    this.joinedAt,
    this.timeZone,
    this.isSupporter,
  });

  factory MalUser.fromMap(Map<String, Object?> map) {
    return MalUser(
      id: _parseInt(map['id']) ?? 0,
      name: _parseString(map['name']) ?? '',
      picture: _parseString(map['picture']),
      gender: _parseString(map['gender']),
      birthday: _parseString(map['birthday']),
      location: _parseString(map['location']),
      joinedAt: _parseString(map['joined_at']),
      timeZone: _parseString(map['time_zone']),
      isSupporter: _parseBool(map['is_supporter']),
    );
  }
}

class MalAnimeListStatus {
  final String? status;
  final int score;
  final int numEpisodesWatched;
  final bool isRewatching;
  final String? updatedAt;
  final int? priority;
  final int? numTimesRewatched;
  final int? rewatchValue;
  final List<String> tags;
  final String? comments;

  MalAnimeListStatus({
    this.status,
    required this.score,
    required this.numEpisodesWatched,
    required this.isRewatching,
    this.updatedAt,
    this.priority,
    this.numTimesRewatched,
    this.rewatchValue,
    required this.tags,
    this.comments,
  });

  factory MalAnimeListStatus.fromMap(Map<String, Object?> map) {
    return MalAnimeListStatus(
      status: _parseString(map['status']),
      score: _parseInt(map['score']) ?? 0,
      numEpisodesWatched: _parseInt(map['num_episodes_watched']) ?? 0,
      isRewatching: _parseBool(map['is_rewatching']) ?? false,
      updatedAt: _parseString(map['updated_at']),
      priority: _parseInt(map['priority']),
      numTimesRewatched: _parseInt(map['num_times_rewatched']),
      rewatchValue: _parseInt(map['rewatch_value']),
      tags: _parseList(map['tags'], (i) => _parseString(i) ?? '') ?? [],
      comments: _parseString(map['comments']),
    );
  }
}

class MalMangaListStatus {
  final String? status;
  final int score;
  final int numVolumesRead;
  final int numChaptersRead;
  final bool isRereading;
  final String? updatedAt;
  final int? priority;
  final int? numTimesReread;
  final int? rereadValue;
  final List<String> tags;
  final String? comments;

  MalMangaListStatus({
    this.status,
    required this.score,
    required this.numVolumesRead,
    required this.numChaptersRead,
    required this.isRereading,
    this.updatedAt,
    this.priority,
    this.numTimesReread,
    this.rereadValue,
    required this.tags,
    this.comments,
  });

  factory MalMangaListStatus.fromMap(Map<String, Object?> map) {
    return MalMangaListStatus(
      status: _parseString(map['status']),
      score: _parseInt(map['score']) ?? 0,
      numVolumesRead: _parseInt(map['num_volumes_read']) ?? 0,
      numChaptersRead: _parseInt(map['num_chapters_read']) ?? 0,
      isRereading: _parseBool(map['is_rereading']) ?? false,
      updatedAt: _parseString(map['updated_at']),
      priority: _parseInt(map['priority']),
      numTimesReread: _parseInt(map['num_times_reread']),
      rereadValue: _parseInt(map['reread_value']),
      tags: _parseList(map['tags'], (i) => _parseString(i) ?? '') ?? [],
      comments: _parseString(map['comments']),
    );
  }
}

// =============================================================================
// Relation & Recommendation Models
// =============================================================================

class MalRelatedAnime {
  final MalAnimeNode node;
  final String relationType;
  final String relationTypeFormatted;

  MalRelatedAnime({
    required this.node,
    required this.relationType,
    required this.relationTypeFormatted,
  });

  factory MalRelatedAnime.fromMap(Map<String, Object?> map) {
    return MalRelatedAnime(
      node: MalAnimeNode.fromMap(asMap(map['node'])),
      relationType: _parseString(map['relation_type']) ?? '',
      relationTypeFormatted: _parseString(map['relation_type_formatted']) ?? '',
    );
  }
}

class MalRelatedManga {
  final MalMangaNode node;
  final String relationType;
  final String relationTypeFormatted;

  MalRelatedManga({
    required this.node,
    required this.relationType,
    required this.relationTypeFormatted,
  });

  factory MalRelatedManga.fromMap(Map<String, Object?> map) {
    return MalRelatedManga(
      node: MalMangaNode.fromMap(asMap(map['node'])),
      relationType: _parseString(map['relation_type']) ?? '',
      relationTypeFormatted: _parseString(map['relation_type_formatted']) ?? '',
    );
  }
}

class MalAnimeRecommendation {
  final MalAnimeNode node;
  final int numRecommendations;

  MalAnimeRecommendation({
    required this.node,
    required this.numRecommendations,
  });

  factory MalAnimeRecommendation.fromMap(Map<String, Object?> map) {
    return MalAnimeRecommendation(
      node: MalAnimeNode.fromMap(asMap(map['node'])),
      numRecommendations: _parseInt(map['num_recommendations']) ?? 0,
    );
  }
}

class MalMangaRecommendation {
  final MalMangaNode node;
  final int numRecommendations;

  MalMangaRecommendation({
    required this.node,
    required this.numRecommendations,
  });

  factory MalMangaRecommendation.fromMap(Map<String, Object?> map) {
    return MalMangaRecommendation(
      node: MalMangaNode.fromMap(asMap(map['node'])),
      numRecommendations: _parseInt(map['num_recommendations']) ?? 0,
    );
  }
}

// =============================================================================
// Anime & Manga Node Models
// =============================================================================

class MalAnimeNode {
  final int id;
  final String title;
  final MalPicture? mainPicture;
  final MalAlternativeTitles? alternativeTitles;
  final String? startDate;
  final String? endDate;
  final String? synopsis;
  final double? mean;
  final int? rank;
  final int? popularity;
  final int? numListUsers;
  final int? numScoringUsers;
  final String? nsfw;
  final String? createdAt;
  final String? updatedAt;
  final String? mediaType;
  final String? status;
  final List<MalNamedNode> genres;
  final MalAnimeListStatus? myListStatus;
  final int? numEpisodes;
  final MalSeason? startSeason;
  final MalBroadcast? broadcast;
  final String? source;
  final int? averageEpisodeDuration;
  final String? rating;
  final List<MalPicture> pictures;
  final String? background;
  final List<MalRelatedAnime> relatedAnime;
  final List<MalRelatedManga> relatedManga;
  final List<MalAnimeRecommendation> recommendations;
  final List<MalNamedNode> studios;

  MalAnimeNode({
    required this.id,
    required this.title,
    this.mainPicture,
    this.alternativeTitles,
    this.startDate,
    this.endDate,
    this.synopsis,
    this.mean,
    this.rank,
    this.popularity,
    this.numListUsers,
    this.numScoringUsers,
    this.nsfw,
    this.createdAt,
    this.updatedAt,
    this.mediaType,
    this.status,
    required this.genres,
    this.myListStatus,
    this.numEpisodes,
    this.startSeason,
    this.broadcast,
    this.source,
    this.averageEpisodeDuration,
    this.rating,
    required this.pictures,
    this.background,
    required this.relatedAnime,
    required this.relatedManga,
    required this.recommendations,
    required this.studios,
  });

  factory MalAnimeNode.fromMap(Map<String, Object?> map) {
    return MalAnimeNode(
      id: _parseInt(map['id']) ?? 0,
      title: _parseString(map['title']) ?? '',
      mainPicture: map['main_picture'] != null
          ? MalPicture.fromMap(asMap(map['main_picture']))
          : null,
      alternativeTitles: map['alternative_titles'] != null
          ? MalAlternativeTitles.fromMap(asMap(map['alternative_titles']))
          : null,
      startDate: _parseString(map['start_date']),
      endDate: _parseString(map['end_date']),
      synopsis: _parseString(map['synopsis']),
      mean: _parseDouble(map['mean']),
      rank: _parseInt(map['rank']),
      popularity: _parseInt(map['popularity']),
      numListUsers: _parseInt(map['num_list_users']),
      numScoringUsers: _parseInt(map['num_scoring_users']),
      nsfw: _parseString(map['nsfw']),
      createdAt: _parseString(map['created_at']),
      updatedAt: _parseString(map['updated_at']),
      mediaType: _parseString(map['media_type']),
      status: _parseString(map['status']),
      genres:
          _parseList(map['genres'], (i) => MalNamedNode.fromMap(asMap(i))) ??
          [],
      myListStatus: map['my_list_status'] != null
          ? MalAnimeListStatus.fromMap(asMap(map['my_list_status']))
          : null,
      numEpisodes: _parseInt(map['num_episodes']),
      startSeason: map['start_season'] != null
          ? MalSeason.fromMap(asMap(map['start_season']))
          : null,
      broadcast: map['broadcast'] != null
          ? MalBroadcast.fromMap(asMap(map['broadcast']))
          : null,
      source: _parseString(map['source']),
      averageEpisodeDuration: _parseInt(map['average_episode_duration']),
      rating: _parseString(map['rating']),
      pictures:
          _parseList(map['pictures'], (i) => MalPicture.fromMap(asMap(i))) ??
          [],
      background: _parseString(map['background']),
      relatedAnime:
          _parseList(
            map['related_anime'],
            (i) => MalRelatedAnime.fromMap(asMap(i)),
          ) ??
          [],
      relatedManga:
          _parseList(
            map['related_manga'],
            (i) => MalRelatedManga.fromMap(asMap(i)),
          ) ??
          [],
      recommendations:
          _parseList(
            map['recommendations'],
            (i) => MalAnimeRecommendation.fromMap(asMap(i)),
          ) ??
          [],
      studios:
          _parseList(map['studios'], (i) => MalNamedNode.fromMap(asMap(i))) ??
          [],
    );
  }
}

class MalMangaNode {
  final int id;
  final String title;
  final MalPicture? mainPicture;
  final MalAlternativeTitles? alternativeTitles;
  final String? startDate;
  final String? endDate;
  final String? synopsis;
  final double? mean;
  final int? rank;
  final int? popularity;
  final int? numListUsers;
  final int? numScoringUsers;
  final String? nsfw;
  final String? createdAt;
  final String? updatedAt;
  final String? mediaType;
  final String? status;
  final List<MalNamedNode> genres;
  final MalMangaListStatus? myListStatus;
  final int? numVolumes;
  final int? numChapters;
  final List<MalAuthor> authors;
  final List<MalPicture> pictures;
  final String? background;
  final List<MalRelatedAnime> relatedAnime;
  final List<MalRelatedManga> relatedManga;
  final List<MalMangaRecommendation> recommendations;
  final List<MalNamedNode> serialization;

  MalMangaNode({
    required this.id,
    required this.title,
    this.mainPicture,
    this.alternativeTitles,
    this.startDate,
    this.endDate,
    this.synopsis,
    this.mean,
    this.rank,
    this.popularity,
    this.numListUsers,
    this.numScoringUsers,
    this.nsfw,
    this.createdAt,
    this.updatedAt,
    this.mediaType,
    this.status,
    required this.genres,
    this.myListStatus,
    this.numVolumes,
    this.numChapters,
    required this.authors,
    required this.pictures,
    this.background,
    required this.relatedAnime,
    required this.relatedManga,
    required this.recommendations,
    required this.serialization,
  });

  factory MalMangaNode.fromMap(Map<String, Object?> map) {
    return MalMangaNode(
      id: _parseInt(map['id']) ?? 0,
      title: _parseString(map['title']) ?? '',
      mainPicture: map['main_picture'] != null
          ? MalPicture.fromMap(asMap(map['main_picture']))
          : null,
      alternativeTitles: map['alternative_titles'] != null
          ? MalAlternativeTitles.fromMap(asMap(map['alternative_titles']))
          : null,
      startDate: _parseString(map['start_date']),
      endDate: _parseString(map['end_date']),
      synopsis: _parseString(map['synopsis']),
      mean: _parseDouble(map['mean']),
      rank: _parseInt(map['rank']),
      popularity: _parseInt(map['popularity']),
      numListUsers: _parseInt(map['num_list_users']),
      numScoringUsers: _parseInt(map['num_scoring_users']),
      nsfw: _parseString(map['nsfw']),
      createdAt: _parseString(map['created_at']),
      updatedAt: _parseString(map['updated_at']),
      mediaType: _parseString(map['media_type']),
      status: _parseString(map['status']),
      genres:
          _parseList(map['genres'], (i) => MalNamedNode.fromMap(asMap(i))) ??
          [],
      myListStatus: map['my_list_status'] != null
          ? MalMangaListStatus.fromMap(asMap(map['my_list_status']))
          : null,
      numVolumes: _parseInt(map['num_volumes']),
      numChapters: _parseInt(map['num_chapters']),
      authors:
          _parseList(map['authors'], (i) => MalAuthor.fromMap(asMap(i))) ?? [],
      pictures:
          _parseList(map['pictures'], (i) => MalPicture.fromMap(asMap(i))) ??
          [],
      background: _parseString(map['background']),
      relatedAnime:
          _parseList(
            map['related_anime'],
            (i) => MalRelatedAnime.fromMap(asMap(i)),
          ) ??
          [],
      relatedManga:
          _parseList(
            map['related_manga'],
            (i) => MalRelatedManga.fromMap(asMap(i)),
          ) ??
          [],
      recommendations:
          _parseList(
            map['recommendations'],
            (i) => MalMangaRecommendation.fromMap(asMap(i)),
          ) ??
          [],
      serialization:
          _parseList(
            map['serialization'],
            (i) => MalNamedNode.fromMap(asMap(i)),
          ) ??
          [],
    );
  }
}

// =============================================================================
// Paginated List Items & Wrapper
// =============================================================================

class MalAnimeListItem {
  final MalAnimeNode node;
  final MalAnimeListStatus? listStatus;
  final MalRanking? ranking;

  MalAnimeListItem({required this.node, this.listStatus, this.ranking});

  factory MalAnimeListItem.fromMap(Map<String, Object?> map) {
    return MalAnimeListItem(
      node: MalAnimeNode.fromMap(asMap(map['node'])),
      listStatus: map['list_status'] != null
          ? MalAnimeListStatus.fromMap(asMap(map['list_status']))
          : null,
      ranking: map['ranking'] != null
          ? MalRanking.fromMap(asMap(map['ranking']))
          : null,
    );
  }
}

class MalMangaListItem {
  final MalMangaNode node;
  final MalMangaListStatus? listStatus;
  final MalRanking? ranking;

  MalMangaListItem({required this.node, this.listStatus, this.ranking});

  factory MalMangaListItem.fromMap(Map<String, Object?> map) {
    return MalMangaListItem(
      node: MalMangaNode.fromMap(asMap(map['node'])),
      listStatus: map['list_status'] != null
          ? MalMangaListStatus.fromMap(asMap(map['list_status']))
          : null,
      ranking: map['ranking'] != null
          ? MalRanking.fromMap(asMap(map['ranking']))
          : null,
    );
  }
}

class MalPaginated<T> {
  final List<T> data;
  final MalPaging? paging;

  MalPaginated({required this.data, this.paging});

  factory MalPaginated.fromMap(
    Map<String, Object?> map,
    T Function(Map<String, Object?> itemMap) itemParser,
  ) {
    final rawData = map['data'];
    final dataList = <T>[];
    if (rawData is List) {
      for (final item in rawData) {
        dataList.add(itemParser(asMap(item)));
      }
    }
    final rawPaging = map['paging'];
    return MalPaginated<T>(
      data: dataList,
      paging: rawPaging != null ? MalPaging.fromMap(asMap(rawPaging)) : null,
    );
  }
}

// =============================================================================
// Forum Models
// =============================================================================

class MalForumSubboard {
  final int id;
  final String title;

  MalForumSubboard({required this.id, required this.title});

  factory MalForumSubboard.fromMap(Map<String, Object?> map) {
    return MalForumSubboard(
      id: _parseInt(map['id']) ?? 0,
      title: _parseString(map['title']) ?? '',
    );
  }
}

class MalForumBoard {
  final int id;
  final String title;
  final String? description;
  final List<MalForumSubboard> subboards;

  MalForumBoard({
    required this.id,
    required this.title,
    this.description,
    required this.subboards,
  });

  factory MalForumBoard.fromMap(Map<String, Object?> map) {
    return MalForumBoard(
      id: _parseInt(map['id']) ?? 0,
      title: _parseString(map['title']) ?? '',
      description: _parseString(map['description']),
      subboards:
          _parseList(
            map['subboards'],
            (i) => MalForumSubboard.fromMap(asMap(i)),
          ) ??
          [],
    );
  }
}

class MalForumCategory {
  final String title;
  final List<MalForumBoard> boards;

  MalForumCategory({required this.title, required this.boards});

  factory MalForumCategory.fromMap(Map<String, Object?> map) {
    return MalForumCategory(
      title: _parseString(map['title']) ?? '',
      boards:
          _parseList(map['boards'], (i) => MalForumBoard.fromMap(asMap(i))) ??
          [],
    );
  }
}

class MalForumPostCreator {
  final int id;
  final String name;
  final String? avatarUrl;

  MalForumPostCreator({required this.id, required this.name, this.avatarUrl});

  factory MalForumPostCreator.fromMap(Map<String, Object?> map) {
    return MalForumPostCreator(
      id: _parseInt(map['id']) ?? 0,
      name: _parseString(map['name']) ?? '',
      avatarUrl: _parseString(map['avatar_url']),
    );
  }
}

class MalForumPost {
  final int id;
  final int number;
  final String? createdAt;
  final MalForumPostCreator? createdBy;
  final String body;
  final String? signature;

  MalForumPost({
    required this.id,
    required this.number,
    this.createdAt,
    this.createdBy,
    required this.body,
    this.signature,
  });

  factory MalForumPost.fromMap(Map<String, Object?> map) {
    return MalForumPost(
      id: _parseInt(map['id']) ?? 0,
      number: _parseInt(map['number']) ?? 0,
      createdAt: _parseString(map['created_at']),
      createdBy: map['created_by'] != null
          ? MalForumPostCreator.fromMap(asMap(map['created_by']))
          : null,
      body: _parseString(map['body']) ?? '',
      signature: _parseString(map['signature']),
    );
  }
}

class MalForumTopicDetail {
  final String title;
  final List<MalForumPost> posts;
  final MalPaging? paging;

  MalForumTopicDetail({required this.title, required this.posts, this.paging});

  factory MalForumTopicDetail.fromMap(Map<String, Object?> map) {
    final dataMap = asMap(map['data']);
    return MalForumTopicDetail(
      title: _parseString(dataMap['title']) ?? _parseString(map['title']) ?? '',
      posts:
          _parseList(
            dataMap['posts'] ?? map['posts'],
            (i) => MalForumPost.fromMap(asMap(i)),
          ) ??
          [],
      paging: map['paging'] != null
          ? MalPaging.fromMap(asMap(map['paging']))
          : null,
    );
  }
}

class MalForumTopic {
  final int id;
  final String title;
  final String? createdAt;
  final MalForumPostCreator? createdBy;
  final int numberOfPosts;
  final String? lastPostCreatedAt;
  final MalForumPostCreator? lastPostCreatedBy;
  final bool isLocked;

  MalForumTopic({
    required this.id,
    required this.title,
    this.createdAt,
    this.createdBy,
    required this.numberOfPosts,
    this.lastPostCreatedAt,
    this.lastPostCreatedBy,
    required this.isLocked,
  });

  factory MalForumTopic.fromMap(Map<String, Object?> map) {
    return MalForumTopic(
      id: _parseInt(map['id']) ?? 0,
      title: _parseString(map['title']) ?? '',
      createdAt: _parseString(map['created_at']),
      createdBy: map['created_by'] != null
          ? MalForumPostCreator.fromMap(asMap(map['created_by']))
          : null,
      numberOfPosts: _parseInt(map['number_of_posts']) ?? 0,
      lastPostCreatedAt: _parseString(map['last_post_created_at']),
      lastPostCreatedBy: map['last_post_created_by'] != null
          ? MalForumPostCreator.fromMap(asMap(map['last_post_created_by']))
          : null,
      isLocked: _parseBool(map['is_locked']) ?? false,
    );
  }
}

class MalForumTopicsResponse {
  final List<MalForumTopic> data;
  final MalPaging? paging;

  MalForumTopicsResponse({required this.data, this.paging});

  factory MalForumTopicsResponse.fromMap(Map<String, Object?> map) {
    return MalForumTopicsResponse(
      data:
          _parseList(map['data'], (i) => MalForumTopic.fromMap(asMap(i))) ?? [],
      paging: map['paging'] != null
          ? MalPaging.fromMap(asMap(map['paging']))
          : null,
    );
  }
}
