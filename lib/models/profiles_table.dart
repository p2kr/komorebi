import 'package:drift/drift.dart' hide JsonKey;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profiles_table.freezed.dart';

@UseRowClass(Profile)
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get username => text()();

  TextColumn get avatarUrl => text().nullable()();

  IntColumn get syncType => intEnum<SyncType>().clientDefault(
    () => SyncType.SANDBOX.index,
  )(); // oauth | sandbox

  DateTimeColumn get connectedOn =>
      dateTime().clientDefault(() => DateTime.timestamp())();

  BoolColumn get isActive => boolean().clientDefault(() => true)();

  TextColumn get accessToken => text().nullable()();

  /// Serialized watching list data
  TextColumn get animeListJson => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {username, isActive},
  ];
}

enum SyncType { OAUTH, SANDBOX }

@Freezed(addImplicitFinal: true)
abstract class Profile with _$Profile {
  const Profile._();

  const factory Profile({
    required int id,
    required String username,
    String? avatarUrl,
    required SyncType syncType,
    required DateTime connectedOn,
    required bool isActive,
    String? accessToken,
    String? animeListJson,
  }) = _Profile;

  @override
  String toString() {
    return "Profile(id: $id, username: $username, syncType: $syncType, isActive: $isActive)";
  }
}
