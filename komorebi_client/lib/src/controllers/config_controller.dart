import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/src/core/services/api/config_api_service.dart';
import 'package:komorebi/src/models/app_config.dart';

/// Get config value or null
Future<String?> getAppConfigValue(Ref ref, String key) async {
  final api = ref.read(configApiServiceProvider);
  final config = await api.getConfig(key);
  return config?.configValue;
}

/// Set config key-value pair
Future<AppConfig> setAppConfig(Ref ref, String key, String value) async {
  final api = ref.read(configApiServiceProvider);
  return await api.setConfig(key, value);
}

/// Delete config by key
Future<void> deleteAppConfig(Ref ref, String key) async {
  final api = ref.read(configApiServiceProvider);
  await api.deleteConfig(key);
}
