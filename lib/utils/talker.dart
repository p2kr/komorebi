import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:talker/talker.dart';

class FileTalkerObserver extends TalkerObserver {
  File? _logFile;
  final String fileName;
  final _queue = <String>[];
  bool _isWriting = false;

  FileTalkerObserver({File? file, this.fileName = 'app_debug.log'}) {
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
      final msg = '${DateTime.now().toIso8601String()} [${log.logLevel?.name ?? "LOG"}] $text\n';
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
        await file.writeAsString(batch, mode: FileMode.append);
      } catch (_) {}
    }
    _isWriting = false;
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
