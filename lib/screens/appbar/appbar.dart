import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/providers/profile_management_provider.dart';
import 'package:komorebi/screens/appbar/diagnostic_window.dart';
import 'package:komorebi/screens/appbar/profile_management.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:komorebi/utils/utils.dart';

AppBar appBar(BuildContext context, WidgetRef ref) {
  final activeProfile = ref.watch(currentProfileProvider);

  return AppBar(
    title: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                APP_NAME,
                style: context.textTheme.headlineMedium,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                S.of(context).automatedCrawlerSyncEngine,
                style: context.textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const Spacer(),
        Row(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => onDiagnosticsPressed(context),
              icon: const Icon(Icons.monitor_heart_outlined),
              label: Text(S.of(context).diagnostics),
            ),
            OutlinedButton.icon(
              onPressed: onCheckNewEpisodePressed,
              icon: const Icon(Icons.notifications_none),
              label: Text(S.of(context).checkNewEpisodes),
            ),
            Container(
              constraints: BoxConstraints(maxWidth: 150),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: .only(
                    right: 4,
                    left: activeProfile.hasValue ? 0 : 4,
                  ),
                  shape: StadiumBorder(),
                ),
                onPressed: () => onManageAccountsPressed(context),
                icon: activeProfile.value != null
                    ? getAvatar(activeProfile.value!, maxRadius: 15)
                    : Icon(Icons.manage_accounts_outlined),
                label: Text(
                  overflow: TextOverflow.ellipsis,
                  activeProfile.value != null
                      ? activeProfile.value!.username
                      : "???",
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    leading: Image.asset(
      "assets/icons/logo.png",
      fit: BoxFit.contain,
      cacheHeight: 70,
      cacheWidth: 70,
    ),
  );
}

void onDiagnosticsPressed(BuildContext context) {
  showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) => DiagnosticWindow(),
  );
}

void onCheckNewEpisodePressed() {
  // TODO:
}

void onManageAccountsPressed(BuildContext context) {
  showDialog(context: context, builder: (context) => ProfileManagementPopup());
}
