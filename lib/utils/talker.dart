import 'package:flutter/material.dart';
import 'package:talker/talker.dart';

/// Default talker instance for this app
final talker = Talker(
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
