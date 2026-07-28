import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/src/core/utils/constants.dart';
import 'package:komorebi/src/core/utils/dio.dart';
import 'package:komorebi/src/models/app_config.dart';

final configApiServiceProvider = Provider<ConfigApiService>((ref) {
  return ConfigApiService();
});

class ConfigApiService {
  final Dio _dio = getDioWithLogger(BaseOptions(baseUrl: API_BASE_URL));

  ConfigApiService();

  Dio get dio => _dio;

  /// Fetch a single config by key from server
  Future<AppConfig?> getConfig(String key) async {
    try {
      final response = await _dio.get(
        '/getConfig',
        queryParameters: {'config_key': key},
      );
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] != null) {
        return AppConfig.fromJson(Map<String, dynamic>.from(data['data']));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Create or update a config on server
  Future<AppConfig> setConfig(String key, String value) async {
    final response = await _dio.post(
      '/setConfig',
      data: {'config_key': key, 'config_value': value},
    );
    final data = response.data;
    if (data != null && data['success'] == true && data['data'] != null) {
      return AppConfig.fromJson(Map<String, dynamic>.from(data['data']));
    }
    throw Exception('Failed to set config for key: $key');
  }

  /// Delete a config by key from server
  Future<void> deleteConfig(String key) async {
    await _dio.delete('/deleteConfig', queryParameters: {'config_key': key});
  }

  /// Fetch all configs from server
  Future<List<AppConfig>> getAllConfigs() async {
    try {
      final response = await _dio.get('/getAllConfigs');
      final data = response.data;
      if (data != null && data['success'] == true && data['data'] is List) {
        final list = data['data'] as List;
        return list
            .map((item) => AppConfig.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
