import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/models/db/profiles_table.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/services/handle_delete.dart';
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
          style: context.textTheme.titleMedium?.copyWith(
            fontFamily: context.fontSerif,
          ),
        ),
        subtitle: Row(
          spacing: 4,
          children: [
            getSyncTypeIcon(profile.syncType),
            Text(profile.syncType.name, style: context.textTheme.labelSmall),
          ],
        ),
        trailing: isCurrentProfileTile(profile, currProfile)
            ? null
            : IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () {
                  // Handle delete event
                  onDeleteProfile(context, ref, profile);
                },
              ),
        onTap: () {
          ref
              .read(currentProfileProvider.notifier)
              .updateCurrentProfile(profile);
        },
      ),
    );
  }
}

void onDeleteProfile(BuildContext context, WidgetRef ref, Profile profile) {
  // ask for confirmation
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(S.of(context).deleteProfileConfirm(profile.username)),
      actions: [
        ElevatedButton(
          onPressed: () async {
            await handleProfileDeletion(ref, profile.id);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: Text(S.of(context).yes.toUpperCase()),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).no.toUpperCase()),
        ),
      ],
    ),
  );
}

bool isCurrentProfileTile(Profile profile, AsyncValue<Profile?> currProfile) {
  return currProfile.value != null ? currProfile.value!.id == profile.id : true;
}
