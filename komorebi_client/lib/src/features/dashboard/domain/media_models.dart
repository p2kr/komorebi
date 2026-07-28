import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_models.freezed.dart';
part 'media_models.g.dart';

enum AnimeStatusFilter {
  watching,
  completed,
  onHold,
  dropped,
  planToWatch;

  String get apiValue => name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

enum MangaStatusFilter {
  reading,
  completed,
  onHold,
  dropped,
  planToRead;

  String get apiValue => name.replaceAllMapped(
    RegExp(r'[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}

Map<String, Object?> asMap(Object? json) {
  if (json is Map) {
    return json.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, Object?>{};
}

@freezed
abstract class MediaTitle with _$MediaTitle {
  const factory MediaTitle({
    String? romanized,
    String? english,
    String? native,
    String? userPreferred,
  }) = _MediaTitle;

  factory MediaTitle.fromJson(Map<String, dynamic> json) =>
      _$MediaTitleFromJson(json);
}

@freezed
abstract class MediaCoverImage with _$MediaCoverImage {
  const factory MediaCoverImage({
    String? extraLarge,
    String? large,
    String? medium,
    String? color,
  }) = _MediaCoverImage;

  factory MediaCoverImage.fromJson(Map<String, dynamic> json) =>
      _$MediaCoverImageFromJson(json);
}

@freezed
abstract class MediaListStatus with _$MediaListStatus {
  const factory MediaListStatus({
    String? status,
    double? score,
    int? progress,
    int? progressVolumes,
    @Default(false) bool isRewatching,
    int? repeatCount,
    @Default([]) List<String> tags,
    String? comments,
    String? updatedAt,
  }) = _MediaListStatus;

  factory MediaListStatus.fromJson(Map<String, dynamic> json) =>
      _$MediaListStatusFromJson(json);
}

@freezed
abstract class MediaItem with _$MediaItem {
  const factory MediaItem({
    required int id,
    int? idMal,
    @Default('mal') String provider,
    @Default(MediaTitle()) MediaTitle title,
    @Default(MediaCoverImage()) MediaCoverImage coverImage,
    String? bannerImage,
    String? synopsis,
    String? format,
    String? status,
    String? season,
    int? seasonYear,
    double? meanScore,
    int? rank,
    int? popularity,
    int? episodes,
    int? chapters,
    int? volumes,
    int? duration,
    @Default([]) List<String> genres,
    @Default([]) List<String> synonyms,
    @Default(false) bool isAdult,
    MediaListStatus? listStatus,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}

@freezed
abstract class PagingInfo with _$PagingInfo {
  const factory PagingInfo({
    String? previous,
    String? next,
    @Default(false) bool hasNextPage,
    int? page,
    int? perPage,
  }) = _PagingInfo;

  factory PagingInfo.fromJson(Map<String, dynamic> json) =>
      _$PagingInfoFromJson(json);
}

@freezed
abstract class MediaPage with _$MediaPage {
  const factory MediaPage({
    @Default([]) List<MediaItem> data,
    @Default(PagingInfo()) PagingInfo paging,
  }) = _MediaPage;

  factory MediaPage.fromJson(Map<String, dynamic> json) =>
      _$MediaPageFromJson(json);
}
