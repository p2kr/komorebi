import 'package:freezed_annotation/freezed_annotation.dart';

part 'mal_models.freezed.dart';
part 'mal_models.g.dart';

// =============================================================================
// Helper Functions
// =============================================================================

int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

int _parseIntRequired(Object? value) => _parseInt(value) ?? 0;

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

bool _parseBoolRequired(Object? value) => _parseBool(value) ?? false;

Map<String, Object?> asMap(Object? json) {
  if (json is Map) {
    return json.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, Object?>{};
}

/// Extension to convert enum names to snake_case for JSON payloads.
extension EnumSnakeCase on Enum {
  String get jsonValue => name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

// =============================================================================
// Common / Shared Models
// =============================================================================

/// Pagination offsets/links returned by list-based MyAnimeList endpoints.
@freezed
abstract class MalPaging with _$MalPaging {
  const factory MalPaging({String? previous, String? next}) = _MalPaging;

  factory MalPaging.fromJson(Map<String, dynamic> json) =>
      _$MalPagingFromJson(json);
}

/// Medium and large URL paths to a specific cover image or avatar graphic.
@freezed
abstract class MalPicture with _$MalPicture {
  const factory MalPicture({String? medium, String? large}) = _MalPicture;

  factory MalPicture.fromJson(Map<String, dynamic> json) =>
      _$MalPictureFromJson(json);
}

/// Alternative titles associated with an anime or manga resource (e.g. English, Japanese, Synonyms).
@freezed
abstract class MalAlternativeTitles with _$MalAlternativeTitles {
  const factory MalAlternativeTitles({
    @Default([]) List<String> synonyms,
    String? en,
    String? ja,
  }) = _MalAlternativeTitles;

  factory MalAlternativeTitles.fromJson(Map<String, dynamic> json) =>
      _$MalAlternativeTitlesFromJson(json);
}

/// Standardized entity representing a node with a unique ID and name string.
@freezed
abstract class MalNamedNode with _$MalNamedNode {
  const factory MalNamedNode({
    @JsonKey(fromJson: _parseIntRequired) required int id,
    @Default('') String name,
  }) = _MalNamedNode;

  factory MalNamedNode.fromJson(Map<String, dynamic> json) =>
      _$MalNamedNodeFromJson(json);
}

/// Information about a manga author node and their contribution role.
@freezed
abstract class MalAuthor with _$MalAuthor {
  const factory MalAuthor({required MalNamedNode node, String? role}) =
      _MalAuthor;

  factory MalAuthor.fromJson(Map<String, dynamic> json) =>
      _$MalAuthorFromJson(json);
}

/// Broadcast schedule metadata detailing the day of the week and local start time.
@freezed
abstract class MalBroadcast with _$MalBroadcast {
  const factory MalBroadcast({String? dayOfTheWeek, String? startTime}) =
      _MalBroadcast;

  factory MalBroadcast.fromJson(Map<String, dynamic> json) =>
      _$MalBroadcastFromJson(json);
}

/// Release season indicators including calendar year and segment name (e.g. spring, fall).
@freezed
abstract class MalSeason with _$MalSeason {
  const factory MalSeason({
    @JsonKey(fromJson: _parseInt) int? year,
    String? season,
  }) = _MalSeason;

  factory MalSeason.fromJson(Map<String, dynamic> json) =>
      _$MalSeasonFromJson(json);
}

/// Ranking position data indicating the item position and previous ranking offsets.
@freezed
abstract class MalRanking with _$MalRanking {
  const factory MalRanking({
    @JsonKey(fromJson: _parseIntRequired) required int rank,
    @JsonKey(fromJson: _parseInt) int? previousRank,
  }) = _MalRanking;

  factory MalRanking.fromJson(Map<String, dynamic> json) =>
      _$MalRankingFromJson(json);
}

// =============================================================================
// User Models
// =============================================================================

/// Basic profile information details representing a MyAnimeList user account.
@freezed
abstract class MalUser with _$MalUser {
  const factory MalUser({
    @JsonKey(fromJson: _parseIntRequired) required int id,
    required String name,
    String? picture,
    String? gender,
    String? birthday,
    String? location,
    String? joinedAt,
    String? timeZone,
    @JsonKey(fromJson: _parseBool) bool? isSupporter,
  }) = _MalUser;

  factory MalUser.fromJson(Map<String, dynamic> json) =>
      _$MalUserFromJson(json);
}

// =============================================================================
// Library Status Models
// =============================================================================

/// Possible statuses for an anime entry in a user's library.
@JsonEnum(fieldRename: FieldRename.snake)
enum MalAnimeStatus { watching, completed, onHold, dropped, planToWatch }

/// Possible statuses for a manga entry in a user's library.
@JsonEnum(fieldRename: FieldRename.snake)
enum MalMangaStatus { reading, completed, onHold, dropped, planToRead }

/// Library metadata representing an anime entry inside the user's personal animelist.
@freezed
abstract class MalAnimeListStatus with _$MalAnimeListStatus {
  const factory MalAnimeListStatus({
    MalAnimeStatus? status,
    @JsonKey(fromJson: _parseIntRequired) required int score,
    @JsonKey(fromJson: _parseIntRequired) required int numEpisodesWatched,
    @JsonKey(fromJson: _parseBoolRequired) required bool isRewatching,
    String? updatedAt,
    @JsonKey(fromJson: _parseInt) int? priority,
    @JsonKey(fromJson: _parseInt) int? numTimesRewatched,
    @JsonKey(fromJson: _parseInt) int? rewatchValue,
    @Default([]) List<String> tags,
    String? comments,
  }) = _MalAnimeListStatus;

  factory MalAnimeListStatus.fromJson(Map<String, dynamic> json) =>
      _$MalAnimeListStatusFromJson(json);
}

/// Library metadata representing a manga entry inside the user's personal mangalist.
@freezed
abstract class MalMangaListStatus with _$MalMangaListStatus {
  const factory MalMangaListStatus({
    MalMangaStatus? status,
    @JsonKey(fromJson: _parseIntRequired) required int score,
    @JsonKey(fromJson: _parseIntRequired) required int numVolumesRead,
    @JsonKey(fromJson: _parseIntRequired) required int numChaptersRead,
    @JsonKey(fromJson: _parseBoolRequired) required bool isRereading,
    String? updatedAt,
    @JsonKey(fromJson: _parseInt) int? priority,
    @JsonKey(fromJson: _parseInt) int? numTimesReread,
    @JsonKey(fromJson: _parseInt) int? rereadValue,
    @Default([]) List<String> tags,
    String? comments,
  }) = _MalMangaListStatus;

  factory MalMangaListStatus.fromJson(Map<String, dynamic> json) =>
      _$MalMangaListStatusFromJson(json);
}

// =============================================================================
// Anime Models
// =============================================================================

/// Complete information details representing an anime entity on MyAnimeList.
@freezed
abstract class MalAnimeNode with _$MalAnimeNode {
  const factory MalAnimeNode({
    @JsonKey(fromJson: _parseIntRequired) required int id,
    required String title,
    MalPicture? mainPicture,
    MalAlternativeTitles? alternativeTitles,
    String? startDate,
    String? endDate,
    String? synopsis,
    @JsonKey(fromJson: _parseDouble) double? mean,
    @JsonKey(fromJson: _parseInt) int? rank,
    @JsonKey(fromJson: _parseInt) int? popularity,
    @JsonKey(fromJson: _parseInt) int? numListUsers,
    @JsonKey(fromJson: _parseInt) int? numScoringUsers,
    String? nsfw,
    String? createdAt,
    String? updatedAt,
    String? mediaType,
    String? status,
    @Default([]) List<MalNamedNode> genres,
    MalAnimeListStatus? myListStatus,
    @JsonKey(fromJson: _parseInt) int? numEpisodes,
    MalSeason? startSeason,
    MalBroadcast? broadcast,
    String? source,
    @JsonKey(fromJson: _parseInt) int? averageEpisodeDuration,
    String? rating,
    @Default([]) List<MalPicture> pictures,
    String? background,
    @Default([]) List<MalRelatedAnime> relatedAnime,
    @Default([]) List<MalRelatedManga> relatedManga,
    @Default([]) List<MalAnimeRecommendation> recommendations,
    @Default([]) List<MalNamedNode> studios,
  }) = _MalAnimeNode;

  factory MalAnimeNode.fromJson(Map<String, dynamic> json) =>
      _$MalAnimeNodeFromJson(json);
}

/// Anime list row item representation enclosing the base node and user's listing details.
@freezed
abstract class MalAnimeListItem with _$MalAnimeListItem {
  const MalAnimeListItem._();

  const factory MalAnimeListItem({
    required MalAnimeNode node,
    MalAnimeListStatus? listStatus,
    MalRanking? ranking,
  }) = _MalAnimeListItem;

  factory MalAnimeListItem.fromJson(Map<String, dynamic> json) =>
      _$MalAnimeListItemFromJson(json);

  factory MalAnimeListItem.fromMap(Map<String, Object?> map) =>
      MalAnimeListItem.fromJson(asMap(map).cast<String, dynamic>());
}

/// Relationship details indicating connection properties to another anime resource.
@freezed
abstract class MalRelatedAnime with _$MalRelatedAnime {
  const factory MalRelatedAnime({
    required MalAnimeNode node,
    @Default('') String relationType,
    @Default('') String relationTypeFormatted,
  }) = _MalRelatedAnime;

  factory MalRelatedAnime.fromJson(Map<String, dynamic> json) =>
      _$MalRelatedAnimeFromJson(json);
}

/// Recommendation indicator linking a recommended anime to the target anime node.
@freezed
abstract class MalAnimeRecommendation with _$MalAnimeRecommendation {
  const factory MalAnimeRecommendation({
    required MalAnimeNode node,
    @JsonKey(fromJson: _parseIntRequired) required int numRecommendations,
  }) = _MalAnimeRecommendation;

  factory MalAnimeRecommendation.fromJson(Map<String, dynamic> json) =>
      _$MalAnimeRecommendationFromJson(json);
}

// =============================================================================
// Manga Models
// =============================================================================

/// Complete information details representing a manga entity on MyAnimeList.
@freezed
abstract class MalMangaNode with _$MalMangaNode {
  const factory MalMangaNode({
    @JsonKey(fromJson: _parseIntRequired) required int id,
    required String title,
    MalPicture? mainPicture,
    MalAlternativeTitles? alternativeTitles,
    String? startDate,
    String? endDate,
    String? synopsis,
    @JsonKey(fromJson: _parseDouble) double? mean,
    @JsonKey(fromJson: _parseInt) int? rank,
    @JsonKey(fromJson: _parseInt) int? popularity,
    @JsonKey(fromJson: _parseInt) int? numListUsers,
    @JsonKey(fromJson: _parseInt) int? numScoringUsers,
    String? nsfw,
    String? createdAt,
    String? updatedAt,
    String? mediaType,
    String? status,
    @Default([]) List<MalNamedNode> genres,
    MalMangaListStatus? myListStatus,
    @JsonKey(fromJson: _parseInt) int? numVolumes,
    @JsonKey(fromJson: _parseInt) int? numChapters,
    @Default([]) List<MalAuthor> authors,
    @Default([]) List<MalPicture> pictures,
    String? background,
    @Default([]) List<MalRelatedAnime> relatedAnime,
    @Default([]) List<MalRelatedManga> relatedManga,
    @Default([]) List<MalMangaRecommendation> recommendations,
    @Default([]) List<MalNamedNode> serialization,
  }) = _MalMangaNode;

  factory MalMangaNode.fromJson(Map<String, dynamic> json) =>
      _$MalMangaNodeFromJson(json);
}

/// Manga list row item representation enclosing the base node and user's listing details.
@freezed
abstract class MalMangaListItem with _$MalMangaListItem {
  const MalMangaListItem._();

  const factory MalMangaListItem({
    required MalMangaNode node,
    MalMangaListStatus? listStatus,
    MalRanking? ranking,
  }) = _MalMangaListItem;

  factory MalMangaListItem.fromJson(Map<String, dynamic> json) =>
      _$MalMangaListItemFromJson(json);

  factory MalMangaListItem.fromMap(Map<String, Object?> map) =>
      MalMangaListItem.fromJson(asMap(map).cast<String, dynamic>());
}

/// Relationship details indicating connection properties to another manga resource.
@freezed
abstract class MalRelatedManga with _$MalRelatedManga {
  const factory MalRelatedManga({
    required MalMangaNode node,
    @Default('') String relationType,
    @Default('') String relationTypeFormatted,
  }) = _MalRelatedManga;

  factory MalRelatedManga.fromJson(Map<String, dynamic> json) =>
      _$MalRelatedMangaFromJson(json);
}

/// Recommendation indicator linking a recommended manga to the target manga node.
@freezed
abstract class MalMangaRecommendation with _$MalMangaRecommendation {
  const factory MalMangaRecommendation({
    required MalMangaNode node,
    @JsonKey(fromJson: _parseIntRequired) required int numRecommendations,
  }) = _MalMangaRecommendation;

  factory MalMangaRecommendation.fromJson(Map<String, dynamic> json) =>
      _$MalMangaRecommendationFromJson(json);
}

// =============================================================================
// Paginated Wrapper
// =============================================================================

/// Generic wrapper enclosing listing payloads with an item data array and paging offset properties.
@Freezed(genericArgumentFactories: true)
abstract class MalPaginated<T> with _$MalPaginated<T> {
  const MalPaginated._();

  const factory MalPaginated({required List<T> data, MalPaging? paging}) =
      _MalPaginated<T>;

  factory MalPaginated.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$MalPaginatedFromJson(json, fromJsonT);

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
      paging: rawPaging != null
          ? MalPaging.fromJson(asMap(rawPaging).cast<String, dynamic>())
          : null,
    );
  }
}

// =============================================================================
// Forum Models
// =============================================================================

/// Subboard categorization container mapping individual forum discussion topics.
@freezed
abstract class MalForumSubboard with _$MalForumSubboard {
  const factory MalForumSubboard({
    @JsonKey(fromJson: _parseIntRequired) required int id,
    @Default('') String title,
  }) = _MalForumSubboard;

  factory MalForumSubboard.fromJson(Map<String, dynamic> json) =>
      _$MalForumSubboardFromJson(json);
}

/// Forum board details including subboards and text descriptions.
@freezed
abstract class MalForumBoard with _$MalForumBoard {
  const factory MalForumBoard({
    @JsonKey(fromJson: _parseIntRequired) required int id,
    @Default('') String title,
    String? description,
    @Default([]) List<MalForumSubboard> subboards,
  }) = _MalForumBoard;

  factory MalForumBoard.fromJson(Map<String, dynamic> json) =>
      _$MalForumBoardFromJson(json);
}

/// Forum category collection mapping lists of available boards.
@freezed
abstract class MalForumCategory with _$MalForumCategory {
  const factory MalForumCategory({
    @Default('') String title,
    @Default([]) List<MalForumBoard> boards,
  }) = _MalForumCategory;

  factory MalForumCategory.fromJson(Map<String, dynamic> json) =>
      _$MalForumCategoryFromJson(json);
}

/// Public profile details summary representing the creator of a forum post.
@freezed
abstract class MalForumPostCreator with _$MalForumPostCreator {
  const factory MalForumPostCreator({
    @JsonKey(fromJson: _parseIntRequired) required int id,
    @Default('') String name,
    String? avatarUrl,
  }) = _MalForumPostCreator;

  factory MalForumPostCreator.fromJson(Map<String, dynamic> json) =>
      _$MalForumPostCreatorFromJson(json);
}

/// Individual reply post element containing content text, numbering, and timestamps.
@freezed
abstract class MalForumPost with _$MalForumPost {
  const factory MalForumPost({
    @JsonKey(fromJson: _parseIntRequired) required int id,
    @JsonKey(fromJson: _parseIntRequired) required int number,
    String? createdAt,
    MalForumPostCreator? createdBy,
    @Default('') String body,
    String? signature,
  }) = _MalForumPost;

  factory MalForumPost.fromJson(Map<String, dynamic> json) =>
      _$MalForumPostFromJson(json);
}

/// Complete discussion topic details structure enclosing title headers and paginated posts.
@freezed
abstract class MalForumTopicDetail with _$MalForumTopicDetail {
  const MalForumTopicDetail._();

  const factory MalForumTopicDetail({
    @Default('') String title,
    @Default([]) List<MalForumPost> posts,
    MalPaging? paging,
  }) = _MalForumTopicDetail;

  factory MalForumTopicDetail.fromJson(Map<String, dynamic> json) {
    final dataMap = asMap(json['data']);
    final title =
        dataMap['title']?.toString() ?? json['title']?.toString() ?? '';
    final rawPosts = dataMap['posts'] ?? json['posts'];
    final postsList = rawPosts is List
        ? rawPosts
              .map(
                (i) => MalForumPost.fromJson(asMap(i).cast<String, dynamic>()),
              )
              .toList()
        : <MalForumPost>[];
    final pagingVal = json['paging'] != null
        ? MalPaging.fromJson(asMap(json['paging']).cast<String, dynamic>())
        : null;
    return MalForumTopicDetail(
      title: title,
      posts: postsList,
      paging: pagingVal,
    );
  }
}

/// Topic details summary detailing reply counts, locked states, and last active details.
@freezed
abstract class MalForumTopic with _$MalForumTopic {
  const factory MalForumTopic({
    @JsonKey(fromJson: _parseIntRequired) required int id,
    @Default('') String title,
    String? createdAt,
    MalForumPostCreator? createdBy,
    @JsonKey(fromJson: _parseIntRequired) required int numberOfPosts,
    String? lastPostCreatedAt,
    MalForumPostCreator? lastPostCreatedBy,
    @JsonKey(fromJson: _parseBoolRequired) required bool isLocked,
  }) = _MalForumTopic;

  factory MalForumTopic.fromJson(Map<String, dynamic> json) =>
      _$MalForumTopicFromJson(json);
}

/// Paginated collection response representing a set of query matching discussion topics.
@freezed
abstract class MalForumTopicsResponse with _$MalForumTopicsResponse {
  const factory MalForumTopicsResponse({
    @Default([]) List<MalForumTopic> data,
    MalPaging? paging,
  }) = _MalForumTopicsResponse;

  factory MalForumTopicsResponse.fromJson(Map<String, dynamic> json) =>
      _$MalForumTopicsResponseFromJson(json);
}
