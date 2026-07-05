import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/screens/appbar/connected_profiles.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/themes/theme.dart';

class ProfileManagementPopup extends ConsumerWidget {
  const ProfileManagementPopup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;

    // final activeProfile -> fetch from state & db config
    // final allProfiles -> fetch from db
    final allProfiles = getConnectedProfiles(ref);

    return Dialog(
      child: Container(
        padding: EdgeInsets.all(8),
        constraints: BoxConstraints(
          maxWidth: size.width * 0.30,
          maxHeight: size.height * 0.75,
        ),
        child: Column(
          spacing: 2,
          mainAxisSize: .min,
          children: [
            // active profile
            Column(
              spacing: 2,
              mainAxisSize: .min,
              mainAxisAlignment: .center,
              // TODO: Dynamic
              children: [
                // avatar icon (fetch from api)
                CircleAvatar(child: Icon(Icons.person)),
                // profile name
                Text(
                  "???",
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontSize: context.textTheme.titleMedium?.fontSize,
                    fontWeight: .bold,
                  ),
                ),

                // type of profile (sandbox or MAL)
                Row(
                  spacing: 2,
                  mainAxisSize: .min,
                  children: [
                    // type of profile icon
                    Transform.rotate(
                      angle: -math.pi / 4, // rotate 45 deg left
                      child: Icon(
                        Icons.key_outlined,
                        size: 14,
                        applyTextScaling: true,
                      ),
                    ),
                    // type of profile text
                    Text(
                      S.of(context).myanimelistOauth,
                      style: context.textTheme.labelSmall,
                    ),
                  ],
                ),

                // profile creation in local db date-time
                Text(
                  "${S.of(context).connectedSince} ${DateFormat().add_yMd().format(DateTime.now())}",
                  style: context.textTheme.labelSmall,
                ),
              ],
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
                child: StreamBuilder(
                  stream: allProfiles,
                  builder: (context, asyncSnapshot) {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: asyncSnapshot.data?.length ?? 0,
                      itemBuilder: (context, index) {
                        if (asyncSnapshot.hasData) {
                          return ConnectedProfiles(
                            profile: asyncSnapshot.data![index],
                          );
                        } else {
                          return Text("No Profiles Found");
                        }
                      },
                    );
                  },
                ),
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

  Stream<List<Profile>> getConnectedProfiles(WidgetRef ref) {
    final db = ref.read(dbProvider);
    return db.profilesDao.watchProfiles();
  }
}
