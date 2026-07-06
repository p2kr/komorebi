import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/screens/appbar/connected_profiles.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/utils.dart';

class ProfileManagementPopup extends ConsumerWidget {
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
                    spacing: 4,
                    mainAxisSize: .min,
                    mainAxisAlignment: .center,
                    children: [
                      // avatar icon (fetch from api)
                      CircleAvatar(
                        minRadius: 32,
                        foregroundImage:
                            activeProfile.avatarUrl != null &&
                                activeProfile.avatarUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(
                                activeProfile.avatarUrl!,
                              )
                            : null,
                        child: (activeProfile.avatarUrl != null
                            ? null
                            : Text(getInitials(activeProfile.username))),
                      ),

                      // profile name
                      Text(
                        activeProfile.username,
                        style: context.textTheme.headlineSmall?.copyWith(
                          fontSize: context.textTheme.titleMedium?.fontSize,
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
                    children: [
                      CircleAvatar(child: Icon(Icons.no_accounts_outlined)),
                      Text("NO ACTIVE PROFILE"),
                    ],
                  ),
                  loading: () => CircularProgressIndicator(),
                ),
              ),
            ),
            Divider(),

            // other connected profiles header text
            Align(
              alignment: .centerLeft,
              child: Text(
                S.of(context).otherConnectedProfiles,
                style: context.textTheme.labelMedium,
              ),
            ),

            // other profiles list
            Flexible(
              child: Material(
                type: .transparency,
                child: switch (allProfilesAsync) {
                  AsyncLoading() => Center(child: CircularProgressIndicator()),
                  AsyncData() => ListView.builder(
                    shrinkWrap: true,
                    itemCount: allProfilesAsync.value.length,
                    itemBuilder: (context, index) => ConnectedProfiles(
                      profile: allProfilesAsync.value[index],
                    ),
                  ),
                  AsyncError() => SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        "No profiles found",
                        style: context.textTheme.labelMedium,
                      ),
                    ),
                  ),
                },
              ),
            ),

            Divider(),

            // link another mal profile using oauth button
            Column(
              spacing: 8,
              crossAxisAlignment: .stretch,
              children: [
                // add another profile
                FilledButton.icon(
                  onPressed: () {},
                  label: Text(S.of(context).linkAnotherMalOauth),
                  icon: Transform.rotate(
                    angle: -math.pi / 4,
                    child: Icon(Icons.key_outlined, applyTextScaling: true),
                  ),
                ),

                // Sandbox link button
                OutlinedButton.icon(
                  onPressed: () {},
                  label: Text(S.of(context).quickSandboxLink),
                  icon: Icon(Icons.person_add_alt, applyTextScaling: true),
                ),

                Divider(),

                // Disconnect active profile button
                TextButton.icon(
                  onPressed: () {},
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

Stream<List<Profile>> getConnectedProfiles(WidgetRef ref) {
  final db = ref.read(dbProvider);
  return db.profilesDao.watchProfiles();
}