import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/src/core/services/api/config_api_service.dart';

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
  late ConfigApiService service;

  setUp(() {
    mockAdapter = MockAdapter();
    service = ConfigApiService();
    service.dio.httpClientAdapter = mockAdapter;
  });

  group('ConfigApiService Tests', () {
    test('getConfig returns AppConfig on success', () async {
      mockAdapter.fetchHandler = (options) {
        expect(options.path, equals("/getConfig"));
        expect(options.queryParameters['config_key'], equals('THEME'));
        return ResponseBody.fromString(
          '{"success":true,"data":{"id":1,"config_key":"THEME","config_value":"dark"}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final config = await service.getConfig('THEME');
      expect(config, isNotNull);
      expect(config!.configKey, equals('THEME'));
      expect(config.configValue, equals('dark'));
    });

    test('setConfig sends JSON body and parses return data', () async {
      mockAdapter.fetchHandler = (options) {
        expect(options.path, equals("/setConfig"));
        return ResponseBody.fromString(
          '{"success":true,"data":{"id":2,"config_key":"TEST_KEY","config_value":"TEST_VAL"}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final config = await service.setConfig('TEST_KEY', 'TEST_VAL');
      expect(config.configKey, equals('TEST_KEY'));
      expect(config.configValue, equals('TEST_VAL'));
    });

    test('deleteConfig completes on 200', () async {
      mockAdapter.fetchHandler = (options) {
        expect(options.path, equals("/deleteConfig"));
        expect(options.queryParameters['config_key'], equals('KEY_TO_DELETE'));
        return ResponseBody.fromString(
          '{"success":true,"data":{"deleted":true}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await service.deleteConfig('KEY_TO_DELETE');
    });

    test('getAllConfigs returns parsed AppConfig list', () async {
      mockAdapter.fetchHandler = (options) {
        expect(options.path, equals("/getAllConfigs"));
        return ResponseBody.fromString(
          '{"success":true,"data":[{"id":1,"config_key":"K1","config_value":"V1"},{"id":2,"config_key":"K2","config_value":"V2"}]}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final configs = await service.getAllConfigs();
      expect(configs.length, equals(2));
      expect(configs.first.configKey, equals('K1'));
      expect(configs.last.configKey, equals('K2'));
    });
  });
}
