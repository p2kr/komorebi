import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:komorebi/src/core/utils/utils.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

enum SyncType { mal, sandbox, anilist }

@Freezed(addImplicitFinal: true)
abstract class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    int? id,
    required String username,
    String? avatarUrl,
    @Default(SyncType.sandbox) SyncType syncType,
    String? accessToken,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _Profile;

  DateTime get connectedOn => createdAt ?? updatedAt ?? DateTime.now();

  bool get isActive => true;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  @override
  String toString() {
    return "Profile(id: $id, username: $username, syncType: $syncType)";
  }
}
