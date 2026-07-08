import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/providers/common_providers.dart';

Future<void> handleProfileDeletion(WidgetRef ref, int id) async {
  // delete from db? the profile watcher should auto handle it?

  final db = ref.read(dbProvider);

  await db.profilesDao.deleteProfile(id);
}
