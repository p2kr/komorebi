import 'package:dio/dio.dart';
import 'package:komorebi/src/core/utils/constants.dart';
import 'package:komorebi/src/core/utils/dio.dart';
import 'package:komorebi/src/core/utils/talker.dart';
import 'package:komorebi/src/features/dashboard/domain/media_models.dart';
import 'package:quiver/strings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_media_api.g.dart';

@Riverpod(keepAlive: true)
ServerMediaApi serverMediaApi(Ref ref) {
  return ServerMediaApi();
}

class ServerMediaApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ServerMediaApiException({required this.message, this.code, this.statusCode});

  @override
  String toString() =>
      'ServerMediaApiException(code: $code, message: $message, statusCode: $statusCode)';
}

class ServerMediaApi {
  final Dio _dio = getDioWithLogger(BaseOptions(baseUrl: API_BASE_URL));

  ServerMediaApi();

  Dio get dio => _dio;

  void dispose() {
    _dio.close();
  }

  Future<MediaPage> getUserAnimeList({
    required String username,
    String? accessToken,
    String? status,
    String? syncType,
    String? provider,
    String? clientId,
  }) => _fetchMediaList(
    '/media/anime',
    _buildQueryParams(
      username: username,
      accessToken: accessToken,
      status: status,
      syncType: syncType,
      provider: provider,
      clientId: clientId,
    ),
  );

  Future<MediaPage> getUserMangaList({
    required String username,
    String? accessToken,
    String? status,
    String? syncType,
    String? provider,
    String? clientId,
  }) => _fetchMediaList(
    '/media/manga',
    _buildQueryParams(
      username: username,
      accessToken: accessToken,
      status: status,
      syncType: syncType,
      provider: provider,
      clientId: clientId,
    ),
  );

  Map<String, String> _buildQueryParams({
    required String username,
    String? accessToken,
    String? status,
    String? syncType,
    String? provider,
    String? clientId,
  }) => {
    'username': username,
    if (isNotBlank(status)) 'status': status!,
    if (isNotBlank(syncType)) 'sync_type': syncType!,
    if (isNotBlank(provider)) 'provider': provider!,
    if (isNotBlank(accessToken)) 'access_token': accessToken!,
    if (isNotBlank(clientId)) 'client_id': clientId!,
  };

  Future<MediaPage> _fetchMediaList(
    String endpoint,
    Map<String, String> queryParams,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data == null) {
        throw ServerMediaApiException(
          message: 'Empty response payload received',
        );
      }

      final success = data['success'] as bool? ?? false;
      if (!success) {
        final err = data['error'] as Map<String, dynamic>?;
        throw ServerMediaApiException(
          message: err?['message']?.toString() ?? 'Server error occurred',
          code: err?['code']?.toString(),
          statusCode: response.statusCode,
        );
      }

      final resData = data['data'];
      return resData is Map<String, dynamic>
          ? MediaPage.fromJson(resData)
          : const MediaPage();
    } on DioException catch (e) {
      talker.error('ServerMediaApi error on $endpoint: ${e.message}');
      throw ServerMediaApiException(
        message: e.message ?? 'Network error connecting to sidecar server',
        statusCode: e.response?.statusCode,
      );
    }
  }
}
