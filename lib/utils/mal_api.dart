import 'package:dio/dio.dart';
import 'package:komorebi/models/mal_models.dart';
import 'package:komorebi/utils/dio.dart';
import 'package:komorebi/utils/talker.dart';

// =============================================================================
// Exceptions & Helpers
// =============================================================================

/// Exception thrown when MyAnimeList API returns an error status code or fails to execute.
class MalApiException implements Exception {
  final int statusCode;
  final String message;
  final String? error;
  final Object? rawResponse;

  MalApiException({
    required this.statusCode,
    required this.message,
    this.error,
    this.rawResponse,
  });

  @override
  String toString() =>
      'MalApiException(statusCode: $statusCode, error: $error, message: $message)';
}

typedef MalApiHelper = MalApi;

// =============================================================================
// Main API Client Service
// =============================================================================

/// Strongly-typed helper class for interacting with the MyAnimeList API v2 using Dio.
///
/// Reference: https://myanimelist.net/apiconfig/references/api/v2
class MalApi {
  static const String baseUrl = 'https://api.myanimelist.net/v2';

  final Dio _dio;
  final String? defaultAccessToken;
  final String? defaultClientId;

  MalApi({Dio? dio, this.defaultAccessToken, this.defaultClientId})
    : _dio = dio ?? getDioWithLogger(BaseOptions(baseUrl: baseUrl)) {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers[Headers.acceptHeader] = 'application/json';
  }

  /// Closes the underlying Dio client.
  void dispose() {
    _dio.close();
  }

  Future<Object?> _sendRequest({
    required String method,
    required String endpoint,
    Map<String, String>? queryParameters,
    Map<String, String>? body,
    String? accessToken,
    String? clientId,
  }) async {
    final token = accessToken ?? defaultAccessToken;
    final client = clientId ?? defaultClientId;

    final headers = <String, Object?>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (client != null && client.isNotEmpty) {
      headers['X-MAL-CLIENT-ID'] = client;
    } else {
      talker.warning(
        'MAL API Request sent without Access Token or Client ID: $endpoint',
      );
    }

    talker.debug('MAL API Request ($method): $endpoint');

    try {
      final response = await _dio.request<Object?>(
        endpoint,
        data: body,
        queryParameters: (queryParameters == null || queryParameters.isEmpty)
            ? null
            : queryParameters,
        options: Options(
          method: method,
          headers: headers,
          contentType: (body != null && (method == 'POST' || method == 'PATCH'))
              ? Headers.formUrlEncodedContentType
              : null,
        ),
      );

      return response.data;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      String errorMessage = 'MyAnimeList API Request Failed';
      String? errorType;
      final rawData = e.response?.data;

      if (rawData is Map) {
        final map = asMap(rawData);
        errorMessage =
            map['message']?.toString() ??
            map['error']?.toString() ??
            errorMessage;
        errorType = map['error']?.toString();
      } else if (rawData is String && rawData.isNotEmpty) {
        errorMessage = rawData;
      } else if (e.message != null && e.message!.isNotEmpty) {
        errorMessage = e.message!;
      }

      talker.error('MAL API Error ($statusCode): $errorMessage');

      throw MalApiException(
        statusCode: statusCode,
        message: errorMessage,
        error: errorType,
        rawResponse: rawData,
      );
    } catch (e) {
      if (e is MalApiException) rethrow;
      talker.error('MAL API Exception on $method $endpoint: $e');
      throw MalApiException(
        statusCode: 500,
        message: 'Network or parsing error: ${e.toString()}',
      );
    }
  }

  // =============================================================================
  // User Endpoints
  // =============================================================================

  /// Get information about the currently authenticated user (`@me`).
  Future<MalUser> getMyUserInfo({
    List<String>? fields,
    String? accessToken,
  }) async {
    final query = <String, String>{};
    if (fields != null && fields.isNotEmpty) {
      query['fields'] = fields.join(',');
    }
    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/users/@me',
      queryParameters: query,
      accessToken: accessToken,
    );
    return MalUser.fromJson(asMap(res).cast<String, dynamic>());
  }

  /// Get the anime list of a user.
  Future<MalPaginated<MalAnimeListItem>> getUserAnimeList({
    required String username,
    String? status,
    String? sort,
    int limit = 100,
    int offset = 0,
    List<String>? fields,
    String? accessToken,
    String? clientId,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) query['status'] = status;
    if (sort != null) query['sort'] = sort;
    if (fields != null && fields.isNotEmpty) {
      query['fields'] = fields.join(',');
    }

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/users/$username/animelist',
      queryParameters: query,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalPaginated<MalAnimeListItem>.fromMap(
      asMap(res),
      MalAnimeListItem.fromMap,
    );
  }

  /// Get the manga list of a user.
  Future<MalPaginated<MalMangaListItem>> getUserMangaList({
    required String username,
    String? status,
    String? sort,
    int limit = 100,
    int offset = 0,
    List<String>? fields,
    String? accessToken,
    String? clientId,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) query['status'] = status;
    if (sort != null) query['sort'] = sort;
    if (fields != null && fields.isNotEmpty) {
      query['fields'] = fields.join(',');
    }

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/users/$username/mangalist',
      queryParameters: query,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalPaginated<MalMangaListItem>.fromMap(
      asMap(res),
      MalMangaListItem.fromMap,
    );
  }

  // =============================================================================
  // Anime Endpoints
  // =============================================================================

  /// Search anime by title query.
  Future<MalPaginated<MalAnimeListItem>> searchAnime({
    required String query,
    int limit = 100,
    int offset = 0,
    List<String>? fields,
    String? accessToken,
    String? clientId,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (fields != null && fields.isNotEmpty) {
      queryParams['fields'] = fields.join(',');
    }

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/anime',
      queryParameters: queryParams,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalPaginated<MalAnimeListItem>.fromMap(
      asMap(res),
      MalAnimeListItem.fromMap,
    );
  }

  /// Get detailed information about a specific anime by ID.
  Future<MalAnimeNode> getAnimeDetails({
    required int animeId,
    List<String>? fields,
    String? accessToken,
    String? clientId,
  }) async {
    final queryParams = <String, String>{};
    if (fields != null && fields.isNotEmpty) {
      queryParams['fields'] = fields.join(',');
    }

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/anime/$animeId',
      queryParameters: queryParams,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalAnimeNode.fromJson(asMap(res).cast<String, dynamic>());
  }

  /// Get anime ranking lists (e.g. all, airing, upcoming, special).
  Future<MalPaginated<MalAnimeListItem>> getAnimeRanking({
    required String rankingType,
    int limit = 100,
    int offset = 0,
    List<String>? fields,
    String? accessToken,
    String? clientId,
  }) async {
    final queryParams = <String, String>{
      'ranking_type': rankingType,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (fields != null && fields.isNotEmpty) {
      queryParams['fields'] = fields.join(',');
    }

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/anime/ranking',
      queryParameters: queryParams,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalPaginated<MalAnimeListItem>.fromMap(
      asMap(res),
      MalAnimeListItem.fromMap,
    );
  }

  /// Get suggested anime recommendations for the authenticated user.
  Future<MalPaginated<MalAnimeListItem>> getAnimeSuggestions({
    int limit = 100,
    int offset = 0,
    List<String>? fields,
    required String accessToken,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (fields != null && fields.isNotEmpty) {
      queryParams['fields'] = fields.join(',');
    }

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/anime/suggestions',
      queryParameters: queryParams,
      accessToken: accessToken,
    );
    return MalPaginated<MalAnimeListItem>.fromMap(
      asMap(res),
      MalAnimeListItem.fromMap,
    );
  }

  /// Add or update the anime list status (e.g. watch status, score, comments) for the user.
  Future<MalAnimeListStatus> updateMyAnimeListStatus({
    required int animeId,
    required String accessToken,
    String? status,
    bool? isRewatching,
    int? score,
    int? numWatchedEpisodes,
    int? priority,
    int? numTimesRewatched,
    int? rewatchValue,
    String? tags,
    String? comments,
  }) async {
    final body = <String, String>{};
    if (status != null) body['status'] = status;
    if (isRewatching != null) body['is_rewatching'] = isRewatching.toString();
    if (score != null) body['score'] = score.toString();
    if (numWatchedEpisodes != null) {
      body['num_watched_episodes'] = numWatchedEpisodes.toString();
    }
    if (priority != null) body['priority'] = priority.toString();
    if (numTimesRewatched != null) {
      body['num_times_rewatched'] = numTimesRewatched.toString();
    }
    if (rewatchValue != null) body['rewatch_value'] = rewatchValue.toString();
    if (tags != null) body['tags'] = tags;
    if (comments != null) body['comments'] = comments;

    final res = await _sendRequest(
      method: 'PATCH',
      endpoint: '/anime/$animeId/my_list_status',
      body: body,
      accessToken: accessToken,
    );
    return MalAnimeListStatus.fromJson(asMap(res).cast<String, dynamic>());
  }

  /// Delete an anime from the user's personal list.
  Future<void> deleteMyAnimeListStatus({
    required int animeId,
    required String accessToken,
  }) async {
    await _sendRequest(
      method: 'DELETE',
      endpoint: '/anime/$animeId/my_list_status',
      accessToken: accessToken,
    );
  }

  // =============================================================================
  // Manga Endpoints
  // =============================================================================

  /// Search manga by title query.
  Future<MalPaginated<MalMangaListItem>> searchManga({
    required String query,
    int limit = 100,
    int offset = 0,
    List<String>? fields,
    String? accessToken,
    String? clientId,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (fields != null && fields.isNotEmpty) {
      queryParams['fields'] = fields.join(',');
    }

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/manga',
      queryParameters: queryParams,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalPaginated<MalMangaListItem>.fromMap(
      asMap(res),
      MalMangaListItem.fromMap,
    );
  }

  /// Get detailed information about a specific manga by ID.
  Future<MalMangaNode> getMangaDetails({
    required int mangaId,
    List<String>? fields,
    String? accessToken,
    String? clientId,
  }) async {
    final queryParams = <String, String>{};
    if (fields != null && fields.isNotEmpty) {
      queryParams['fields'] = fields.join(',');
    }

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/manga/$mangaId',
      queryParameters: queryParams,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalMangaNode.fromJson(asMap(res).cast<String, dynamic>());
  }

  /// Get manga ranking lists (e.g. all, manga, novels, oneshots).
  Future<MalPaginated<MalMangaListItem>> getMangaRanking({
    required String rankingType,
    int limit = 100,
    int offset = 0,
    List<String>? fields,
    String? accessToken,
    String? clientId,
  }) async {
    final queryParams = <String, String>{
      'ranking_type': rankingType,
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (fields != null && fields.isNotEmpty) {
      queryParams['fields'] = fields.join(',');
    }

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/manga/ranking',
      queryParameters: queryParams,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalPaginated<MalMangaListItem>.fromMap(
      asMap(res),
      MalMangaListItem.fromMap,
    );
  }

  /// Add or update the manga list status (e.g. read status, chapters, comments) for the user.
  Future<MalMangaListStatus> updateMyMangaListStatus({
    required int mangaId,
    required String accessToken,
    String? status,
    bool? isRereading,
    int? score,
    int? numVolumesRead,
    int? numChaptersRead,
    int? priority,
    int? numTimesReread,
    int? rereadValue,
    String? tags,
    String? comments,
  }) async {
    final body = <String, String>{};
    if (status != null) body['status'] = status;
    if (isRereading != null) body['is_rereading'] = isRereading.toString();
    if (score != null) body['score'] = score.toString();
    if (numVolumesRead != null) {
      body['num_volumes_read'] = numVolumesRead.toString();
    }
    if (numChaptersRead != null) {
      body['num_chapters_read'] = numChaptersRead.toString();
    }
    if (priority != null) body['priority'] = priority.toString();
    if (numTimesReread != null) {
      body['num_times_reread'] = numTimesReread.toString();
    }
    if (rereadValue != null) body['reread_value'] = rereadValue.toString();
    if (tags != null) body['tags'] = tags;
    if (comments != null) body['comments'] = comments;

    final res = await _sendRequest(
      method: 'PATCH',
      endpoint: '/manga/$mangaId/my_list_status',
      body: body,
      accessToken: accessToken,
    );
    return MalMangaListStatus.fromJson(asMap(res).cast<String, dynamic>());
  }

  /// Delete a manga from the user's personal list.
  Future<void> deleteMyMangaListStatus({
    required int mangaId,
    required String accessToken,
  }) async {
    await _sendRequest(
      method: 'DELETE',
      endpoint: '/manga/$mangaId/my_list_status',
      accessToken: accessToken,
    );
  }

  // =============================================================================
  // Forum Endpoints
  // =============================================================================

  /// Get the list of all available forum categories and boards.
  Future<List<MalForumCategory>> getForumBoards({
    String? accessToken,
    String? clientId,
  }) async {
    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/forum/boards',
      accessToken: accessToken,
      clientId: clientId,
    );
    final map = asMap(res);
    final categories = map['categories'];
    if (categories is List) {
      return categories.map((i) => MalForumCategory.fromJson(asMap(i).cast<String, dynamic>())).toList();
    }
    return [];
  }

  /// Get the detailed post listing for a specific forum discussion topic ID.
  Future<MalForumTopicDetail> getForumTopic({
    required int topicId,
    int limit = 100,
    int offset = 0,
    String? accessToken,
    String? clientId,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/forum/topic/$topicId',
      queryParameters: queryParams,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalForumTopicDetail.fromJson(asMap(res).cast<String, dynamic>());
  }

  /// Search or query general forum topics with filter criteria.
  Future<MalForumTopicsResponse> getForumTopics({
    int? boardId,
    int? subboardId,
    int limit = 100,
    int offset = 0,
    String? sort,
    String? query,
    String? topicUserName,
    String? userName,
    String? accessToken,
    String? clientId,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (boardId != null) queryParams['board_id'] = boardId.toString();
    if (subboardId != null) queryParams['subboard_id'] = subboardId.toString();
    if (sort != null) queryParams['sort'] = sort;
    if (query != null) queryParams['q'] = query;
    if (topicUserName != null) queryParams['topic_user_name'] = topicUserName;
    if (userName != null) queryParams['user_name'] = userName;

    final res = await _sendRequest(
      method: 'GET',
      endpoint: '/forum/topics',
      queryParameters: queryParams,
      accessToken: accessToken,
      clientId: clientId,
    );
    return MalForumTopicsResponse.fromJson(asMap(res).cast<String, dynamic>());
  }
}
