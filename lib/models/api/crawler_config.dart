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
    @JsonKey(includeFromJson: false) CrawlerParsedTitle? parsedTitle,
  }) = _CrawlerResult;

  factory CrawlerResult.fromJson(Map<String, dynamic> json) =>
      _$CrawlerResultFromJson(json);
}

@freezed
abstract class CrawlerParsedTitle with _$CrawlerParsedTitle {
  const factory CrawlerParsedTitle({
    String? audioTerm,
    String? device,
    String? episode,
    String? episodeTitle,
    String? fileChecksum,
    String? fileExtension,
    String? language,
    String? other,
    String? part,
    String? releaseGroup,
    String? releaseInformation,
    String? releaseVersion,
    String? season,
    String? source,
    String? subtitles,
    String? title,
    String? type,
    String? videoResolution,
    String? videoTerm,
    String? volume,
    String? year,
  }) = _CrawlerParsedTitle;

  factory CrawlerParsedTitle.fromJson(Map<String, dynamic> json) =>
      _$CrawlerParsedTitleFromJson(json);
}
