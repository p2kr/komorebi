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
    required String downloadUrl,
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
  const factory CrawlerParsedTitle({
    @StringOrListConverter() List<String>? audioTerm,
    @StringOrListConverter() List<String>? device,
    @StringOrListConverter() List<String>? episode,
    @StringOrListConverter() List<String>? episodeTitle,
    @StringOrListConverter() List<String>? fileChecksum,
    @StringOrListConverter() List<String>? fileExtension,
    @StringOrListConverter() List<String>? language,
    @StringOrListConverter() List<String>? other,
    @StringOrListConverter() List<String>? part,
    @StringOrListConverter() List<String>? releaseGroup,
    @StringOrListConverter() List<String>? releaseInformation,
    @StringOrListConverter() List<String>? releaseVersion,
    @StringOrListConverter() List<String>? season,
    @StringOrListConverter() List<String>? source,
    @StringOrListConverter() List<String>? subtitles,
    @StringOrListConverter() List<String>? title,
    @StringOrListConverter() List<String>? type,
    @StringOrListConverter() List<String>? videoResolution,
    @StringOrListConverter() List<String>? videoTerm,
    @StringOrListConverter() List<String>? volume,
    @StringOrListConverter() List<String>? year,
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
