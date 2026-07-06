import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komorebi/models/profiles_table.dart';
import 'package:komorebi/services/database.dart';

String getInitials(String name) {
  if (name.isEmpty) return "??";
  return name.substring(0, math.min(2, name.length)).toUpperCase();
}

String getDateOnly(DateTime? dateTime) {
  if (dateTime == null) return "???";
  return DateFormat().add_yMd().format(dateTime.toLocal());
}

Widget getSyncTypeIcon(SyncType? syncType) => switch (syncType) {
  .OAUTH => Transform.rotate(
    angle: -math.pi / 4,
    child: Icon(Icons.key_outlined, size: 14, applyTextScaling: true),
  ),
  .SANDBOX => Icon(Icons.person_add_alt, size: 14, applyTextScaling: true),
  _ => Icon(Icons.no_accounts_outlined, size: 14, applyTextScaling: true),
};

CircleAvatar getAvatar(Profile? profile, {
  double? minRadius,
  double? maxRadius,
  double? radius,
}) => CircleAvatar(
  foregroundImage:
      profile != null &&
          profile.avatarUrl != null &&
          profile.avatarUrl!.isNotEmpty
      ? CachedNetworkImageProvider(profile.avatarUrl!)
      : null,
  radius: radius,
  minRadius: minRadius,
  maxRadius: maxRadius,
  child:
      profile == null || profile.avatarUrl == null || profile.avatarUrl!.isEmpty
      ? Text(getInitials(profile!.username))
      : null,
);
