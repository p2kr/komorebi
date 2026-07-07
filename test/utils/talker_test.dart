import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:talker/talker.dart';

void main() {
  group('FileTalkerObserver Tests', () {
    late Directory tempDir;
    late File testFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('talker_test_');
      testFile = File('${tempDir.path}/test_log.log');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('writes logs asynchronously to custom file without blocking', () async {
      final observer = FileTalkerObserver(file: testFile);
      final talker = Talker(observer: observer);

      talker.info('Test info message');
      talker.warning('Test warning message');

      // Wait for async queue to process
      await Future.delayed(const Duration(milliseconds: 300));

      expect(testFile.existsSync(), isTrue);
      final content = testFile.readAsStringSync();
      expect(content, contains('Test info message'));
      expect(content, contains('Test warning message'));
    });

    test('handles onError and onException', () async {
      final observer = FileTalkerObserver(file: testFile);
      final talker = Talker(observer: observer);

      talker.error('Test error', Exception('something broke'));
      talker.handle(Exception('fatal exception'), null, 'Test exception');

      await Future.delayed(const Duration(milliseconds: 300));

      expect(testFile.existsSync(), isTrue);
      final content = testFile.readAsStringSync();
      expect(content, contains('Test error'));
      expect(content, contains('something broke'));
      expect(content, contains('fatal exception'));
    });
  });
}
