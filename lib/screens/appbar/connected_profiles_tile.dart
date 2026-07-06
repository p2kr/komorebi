import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/utils.dart';

class ConnectedProfilesTile extends ConsumerWidget {
  const ConnectedProfilesTile({super.key, required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currProfile = ref.watch(currentProfileProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        enabled: !isCurrentProfileTile(profile, currProfile),
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Theme.of(context).dividerColor),
        ),
        leading: getAvatar(profile),
        title: Text(
          profile.username,
          style: context.textTheme.headlineSmall?.copyWith(
            fontSize: context.textTheme.titleMedium?.fontSize,
          ),
        ),
        subtitle: Row(
          spacing: 4,
          children: [
            getSyncTypeIcon(profile.syncType),
            Text(profile.syncType.name, style: context.textTheme.labelSmall),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline),
          onPressed: () {
            // Handle delete event
          },
        ),
        onTap: () {
          // Handle tap event
        },
      ),
    );
  }
}

bool isCurrentProfileTile(Profile profile, AsyncValue<Profile?> currProfile) {
  return currProfile.value != null ? currProfile.value!.id == profile.id : true;
}
