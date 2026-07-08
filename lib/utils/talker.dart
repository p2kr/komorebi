import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker/talker.dart';

class FileTalkerObserver extends TalkerObserver {
  File? _logFile;
  final String fileName;
  final int maxFileSize;
  final int maxBackups;
  final _queue = <String>[];
  bool _isWriting = false;

  FileTalkerObserver({
    File? file,
    this.fileName = 'app_debug.log',
    this.maxFileSize = 5 * 1024 * 1024, // 5 MB default
    this.maxBackups = 1, // 1 backup file default
  }) {
    if (file != null) {
      _logFile = file;
    } else {
      _initLogFile();
    }
  }

  File? get logFile => _logFile;

  Future<void> _initLogFile() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationSupportDirectory();
      _logFile = File('${dir.path}${Platform.pathSeparator}$fileName');
    } catch (_) {
      // Fallback if path_provider fails (e.g. during standalone unit tests)
      _logFile = File(fileName);
    }
    _processQueue();
  }

  @override
  void onLog(TalkerData log) => _writeLog(log);

  @override
  void onError(TalkerError err) => _writeLog(err);

  @override
  void onException(TalkerException err) => _writeLog(err);

  void _writeLog(TalkerData log) {
    if (kIsWeb) return;
    try {
      final text = log.generateTextMessage();
      final lines = text.split('\n').map((e) => '│ $e').join('\n');
      final topline = ConsoleUtils.getTopline(110, withCorner: true);
      final underline = ConsoleUtils.getUnderline(110, withCorner: true);
      final msg = '$topline\n$lines\n$underline\n';
      _queue.add(msg);
      _processQueue();
    } catch (_) {}
  }

  Future<void> _processQueue() async {
    if (_isWriting || _queue.isEmpty) return;
    _isWriting = true;
    while (_queue.isNotEmpty) {
      var file = _logFile;
      if (file == null) {
        // Wait briefly for _initLogFile to complete if still initializing
        await Future.delayed(const Duration(milliseconds: 50));
        file = _logFile;
        if (file == null) break;
      }
      final batch = _queue.join('');
      _queue.clear();
      try {
        if (await file.exists() && (await file.length()) + batch.length > maxFileSize) {
          await _rollFile(file);
        }
        await file.writeAsString(batch, mode: FileMode.append);
      } catch (_) {}
    }
    _isWriting = false;
  }

  Future<void> _rollFile(File file) async {
    try {
      for (var i = maxBackups - 1; i >= 1; i--) {
        final current = File('${file.path}.$i');
        final next = File('${file.path}.${i + 1}');
        if (await current.exists()) {
          if (await next.exists()) {
            await next.delete();
          }
          await current.rename(next.path);
        }
      }
      if (maxBackups > 0) {
        final backup1 = File('${file.path}.1');
        if (await backup1.exists()) {
          await backup1.delete();
        }
        await file.rename(backup1.path);
      } else {
        await file.delete();
      }
    } catch (_) {}
  }
}

/// Default talker instance for this app
final talker = Talker(
  observer: FileTalkerObserver(),
  settings: TalkerSettings(
    //...
  ),
  logger: TalkerLogger(
    settings: TalkerLoggerSettings(
      //...
    ),
  ),
);

extension TalkerDataFlutterExt on TalkerData {
  Color getFlutterColor() {
    Color? color;
    if (logLevel != null) {
      color = levelVsColorMap[logLevel!.name];
    }
    return color ?? Colors.grey;
  }
}

final levelVsColorMap = {
  "info": Colors.green,
  "debug": Colors.blue,
  "warning": Colors.orange,
  "error": Colors.red,
};
