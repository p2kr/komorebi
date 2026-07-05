import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/services/mal_api.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return await handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('MalApi service requests using Dio', () {
    late MalApi api;
    late Dio dio;

    setUp(() {
      dio = Dio();
      api = MalApi(dio: dio, defaultClientId: 'default_client_id');
    });

    tearDown(() {
      api.dispose();
    });

    test(
      'getMyUserInfo sends GET request to /users/@me with Authorization header',
      () async {
        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          expect(options.method, 'GET');
          expect(options.path, '/users/@me');
          expect(options.headers['Authorization'], 'Bearer my_test_token');
          expect(options.queryParameters['fields'], 'id,name,picture');

          return ResponseBody.fromString(
            jsonEncode({
              'id': 1,
              'name': 'KomorebiUser',
              'picture': 'https://example.com/picture.jpg',
              'is_supporter': true,
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final user = await api.getMyUserInfo(
          fields: ['id', 'name', 'picture'],
          accessToken: 'my_test_token',
        );

        expect(user.id, 1);
        expect(user.name, 'KomorebiUser');
        expect(user.picture, 'https://example.com/picture.jpg');
        expect(user.isSupporter, true);
      },
    );

    test(
      'getUserAnimeList sends query parameters and client ID correctly',
      () async {
        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          expect(options.method, 'GET');
          expect(options.path, '/users/prince/animelist');
          expect(options.headers['X-MAL-CLIENT-ID'], 'default_client_id');
          expect(options.queryParameters['status'], 'watching');
          expect(options.queryParameters['limit'], '50');
          expect(options.queryParameters['offset'], '0');

          return ResponseBody.fromString(
            jsonEncode({
              'data': [
                {
                  'node': {'id': 100, 'title': 'Mob Psycho 100'},
                  'list_status': {
                    'status': 'watching',
                    'score': 10,
                    'num_episodes_watched': 6,
                    'is_rewatching': false,
                  },
                },
              ],
              'paging': {},
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final list = await api.getUserAnimeList(
          username: 'prince',
          status: 'watching',
          limit: 50,
        );

        expect(list.data.length, 1);
        expect(list.data[0].node.title, 'Mob Psycho 100');
        expect(list.data[0].listStatus?.score, 10);
      },
    );

    test(
      'updateMyAnimeListStatus sends PATCH request with form-urlencoded body',
      () async {
        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          expect(options.method, 'PATCH');
          expect(options.path, '/anime/5/my_list_status');
          expect(options.headers['Authorization'], 'Bearer auth_token');
          expect(options.contentType, Headers.formUrlEncodedContentType);
          expect(options.data, {
            'status': 'completed',
            'score': '9',
            'num_watched_episodes': '12',
            'is_rewatching': 'false',
          });

          return ResponseBody.fromString(
            jsonEncode({
              'status': 'completed',
              'score': 9,
              'num_episodes_watched': 12,
              'is_rewatching': false,
              'tags': [],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final status = await api.updateMyAnimeListStatus(
          animeId: 5,
          accessToken: 'auth_token',
          status: 'completed',
          score: 9,
          numWatchedEpisodes: 12,
          isRewatching: false,
        );

        expect(status.status, 'completed');
        expect(status.score, 9);
        expect(status.numEpisodesWatched, 12);
      },
    );

    test('deleteMyAnimeListStatus sends DELETE request', () async {
      bool deleteCalled = false;
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.method, 'DELETE');
        expect(options.path, '/anime/5/my_list_status');
        expect(options.headers['Authorization'], 'Bearer auth_token');
        deleteCalled = true;

        return ResponseBody.fromString(
          '',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      await api.deleteMyAnimeListStatus(animeId: 5, accessToken: 'auth_token');
      expect(deleteCalled, isTrue);
    });

    test(
      'throws MalApiException with structured error on 401 Unauthorized',
      () async {
        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          return ResponseBody.fromString(
            jsonEncode({
              'error': 'invalid_token',
              'message': 'The access token is expired or invalid.',
            }),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        expect(
          () => api.getMyUserInfo(accessToken: 'bad_token'),
          throwsA(
            isA<MalApiException>()
                .having((e) => e.statusCode, 'statusCode', 401)
                .having((e) => e.error, 'error', 'invalid_token')
                .having(
                  (e) => e.message,
                  'message',
                  'The access token is expired or invalid.',
                ),
          ),
        );
      },
    );

    test('throws MalApiException on 404 Not Found', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'error': 'not_found', 'message': 'Anime not found'}),
          404,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      expect(
        () => api.getAnimeDetails(animeId: 999999),
        throwsA(
          isA<MalApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Anime not found'),
        ),
      );
    });

    test('throws MalApiException on network/adapter exception', () async {
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        throw DioException(
          requestOptions: options,
          error: 'Connection refused',
          type: DioExceptionType.connectionError,
        );
      });

      expect(
        () => api.searchAnime(query: 'test'),
        throwsA(
          isA<MalApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });
}
