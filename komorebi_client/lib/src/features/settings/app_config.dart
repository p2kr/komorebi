import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

@Freezed(addImplicitFinal: true)
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    int? id,
    required String configKey,
    String? configValue,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);
}
