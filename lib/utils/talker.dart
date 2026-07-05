import 'package:flutter/material.dart';
import 'package:talker/talker.dart';

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
    if (key != null) {
      color = levelVsColorMap[key];
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
