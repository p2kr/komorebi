import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komorebi/models/profiles_table.dart';

String getInitials(String name) {
  if (name.isEmpty) return "??";
  return name.substring(0, math.min(2, name.length)).toUpperCase();
}

String getDateOnly(DateTime? dateTime) {
  if (dateTime == null) return "???";
  return DateFormat().add_yMd().format(dateTime);
}

Widget getSyncTypeIcon(SyncType? syncType) => switch (syncType) {
  .OAUTH => Transform.rotate(
    angle: -math.pi / 4,
    child: Icon(Icons.key_outlined, size: 14, applyTextScaling: true),
  ),
  .SANDBOX => Icon(Icons.person_add_alt, size: 14, applyTextScaling: true),
  _ => Icon(Icons.no_accounts_outlined, size: 14, applyTextScaling: true),
};
