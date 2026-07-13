import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/screens/appbar/connected_profiles_tile.dart';
import 'package:komorebi/screens/appbar/sanbox_new_user_popup.dart';
import 'package:komorebi/services/handle_sync.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/utils.dart';

class ProfileManagementPopup extends HookConsumerWidget {
  const ProfileManagementPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    // final activeProfile -> fetch from state & db config
    final activeProfileAsync = ref.watch(currentProfileProvider);
    // final allProfiles -> fetch from db
    final allProfilesAsync = ref.watch(allProfilesProvider);

    return Dialog(
      child: Container(
        padding: EdgeInsets.all(8),
        constraints: BoxConstraints(
          maxWidth: size.width * 0.25,
          maxHeight: size.height * 0.75,
        ),
        child: Column(
          spacing: 2,
          mainAxisSize: .min,
          children: [
            // active profile
            Container(
              constraints: BoxConstraints(minHeight: 100),
              child: Center(
                child: activeProfileAsync.when(
                  data: (activeProfile) => Column(
                    spacing: 8,
                    mainAxisSize: .min,
                    mainAxisAlignment: .center,
                    children: activeProfile == null
                        ? noActiveProfileWidget(context)
                        : [
                            // avatar icon (fetch from api)
                            getAvatar(activeProfile, radius: 32),

                            // profile name
                            Text(
                              activeProfile.username,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontFamily: context.fontSerif,
                                fontWeight: .bold,
                              ),
                            ),

                            // type of profile (sandbox or oauth)
                            Row(
                              spacing: 2,
                              mainAxisSize: .min,
                              children: [
                                getSyncTypeIcon(activeProfile.syncType),
                                Text(
                                  activeProfile.syncType.name,
                                  style: context.textTheme.labelSmall,
                                ),
                              ],
                            ),

                            // profile creation in local db date-time
                            Text(
                              "${S.of(context).connectedSince} ${getDateOnly(activeProfile.connectedOn)}",
                              style: context.textTheme.labelSmall,
                            ),
                          ],
                  ),
                  error: (error, stackTrace) => Column(
                    spacing: 8,
                    children: noActiveProfileWidget(context),
                  ),
                  loading: () => CircularProgressIndicator(),
                ),
              ),
            ),
            Divider(),

            ...allProfilesAsync.when(
              data: (profiles) => [
                // other connected profiles header text
                Align(
                  alignment: .centerLeft,
                  child: Text(
                    profiles.isNotEmpty
                        ? S.of(context).otherConnectedProfiles
                        : S.of(context).noProfilesFound,
                    style: context.textTheme.labelMedium,
                  ),
                ),

                // list of other profiles
                Flexible(
                  child: Material(
                    type: .transparency,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: profiles.length,
                      itemBuilder: (context, index) {
                        return ConnectedProfilesTile(profile: profiles[index]);
                      },
                    ),
                  ),
                ),
              ],
              error: (e, trace) => [
                Container(
                  constraints: BoxConstraints(maxHeight: 100),
                  child: Center(
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        IconButton(
                          onPressed: () {
                            ref.invalidate(allProfilesProvider);
                            ref.invalidate(currentProfileProvider);
                          },
                          icon: Icon(Icons.refresh_outlined),
                        ),
                        Text(
                          S.of(context).errorFetchingProfiles,
                          style: context.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              loading: () => [Center(child: CircularProgressIndicator())],
            ),

            Divider(),

            // link another mal profile using oauth button
            Column(
              spacing: 8,
              crossAxisAlignment: .stretch,
              children: [
                // add another profile
                FilledButton.icon(
                  onPressed: () {
                    onLinkWithOAuthPressed(context, ref);
                  },
                  label: Text(S.of(context).linkAnotherMalOauth),
                  icon: Transform.rotate(
                    angle: -math.pi / 4,
                    child: Icon(Icons.key_outlined, applyTextScaling: true),
                  ),
                ),

                // Sandbox link button
                OutlinedButton.icon(
                  onPressed: () {
                    onQuickSandboxLinkPressed(context, ref);
                  },
                  label: Text(S.of(context).quickSandboxLink),
                  icon: Icon(Icons.person_add_alt, applyTextScaling: true),
                ),

                Divider(),

                // Disconnect active profile button
                TextButton.icon(
                  onPressed: () {
                    if (activeProfileAsync.value != null) {
                      onDeleteProfile(context, ref, activeProfileAsync.value!);
                    }
                  },
                  label: Text(S.of(context).disconnectActiveProfile),
                  icon: Icon(Icons.logout_outlined, applyTextScaling: true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> noActiveProfileWidget(BuildContext context) {
  return [
    CircleAvatar(child: Icon(Icons.no_accounts_outlined)),
    Text(S.of(context).noActiveProfile),
  ];
}

void onQuickSandboxLinkPressed(BuildContext context, WidgetRef ref) {
  // final userName = useState("");
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => SanboxNewUserPopup(),
  );
}

void onLinkWithOAuthPressed(BuildContext context, WidgetRef ref) {
  signInWithOAuth(ref)
      .then((value) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).profileLinkedSuccessfully)),
        );
        Navigator.pop(context);
      })
      .onError((e, t) {
        if (!context.mounted) return;

        final snackbar = SnackBar(
          content: Text("${S.of(context).unableToLinkProfile}: $e"),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackbar);
      });
}
