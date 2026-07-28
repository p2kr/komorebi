import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/src/core/services/api/profile_api_service.dart';
import 'package:komorebi/src/models/profile.dart';

class MockAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) fetchHandler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return fetchHandler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late MockAdapter mockAdapter;
  late ProfileApiService service;

  setUp(() {
    mockAdapter = MockAdapter();
    service = ProfileApiService();
    service.dio.httpClientAdapter = mockAdapter;
  });

  group('ProfileApiService Tests', () {
    test('getAllProfiles returns parsed profile list on 200', () async {
      mockAdapter.fetchHandler = (options) {
        expect(options.path, equals("/getAllProfiles"));
        return ResponseBody.fromString(
          '{"success":true,"data":[{"id":1,"username":"TestUser","sync_type":"mal","created_at":"2026-01-01T00:00:00.000Z"}]}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final profiles = await service.getAllProfiles();
      expect(profiles.length, equals(1));
      expect(profiles.first.id, equals(1));
      expect(profiles.first.username, equals('TestUser'));
      expect(profiles.first.syncType, equals(SyncType.mal));
    });

    test('getProfile returns single matching profile', () async {
      mockAdapter.fetchHandler = (options) {
        return ResponseBody.fromString(
          '{"success":true,"data":[{"id":10,"username":"TargetUser","sync_type":"sandbox"}]}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final profile = await service.getProfile(10);
      expect(profile, isNotNull);
      expect(profile!.username, equals('TargetUser'));
      expect(profile.syncType, equals(SyncType.sandbox));
    });

    test('addNewProfile sends JSON body and parses returned profile', () async {
      mockAdapter.fetchHandler = (options) {
        expect(options.path, equals("/addNewProfile"));
        return ResponseBody.fromString(
          '{"success":true,"data":{"id":5,"username":"NewUser","sync_type":"mal"}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final profile = Profile(
        id: 0,
        username: 'NewUser',
        syncType: SyncType.mal,
        createdAt: DateTime.now(),
      );

      final result = await service.addNewProfile(profile);
      expect(result.id, equals(5));
      expect(result.username, equals('NewUser'));
    });

    test('deleteProfile completes on 200', () async {
      mockAdapter.fetchHandler = (options) {
        expect(options.path, equals("/deleteProfile"));
        expect(options.queryParameters['id'], equals(5));
        return ResponseBody.fromString(
          '{"success":true,"data":{"deleted":true}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await service.deleteProfile(5);
    });
  });
}
