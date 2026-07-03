import 'package:flutter/material.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/screens/appbar/diagnostic_window.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/constants.dart';

AppBar appBar(BuildContext context) {
  return AppBar(
    title: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              APP_NAME,
              style: context.textTheme.headlineMedium,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              S.of(context).automatedCrawlerSyncEngine.toUpperCase(),
              style: context.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
            OutlinedButton(
              style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: onManageAccountsPressed,
              child: const Icon(Icons.manage_accounts_outlined),
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

void onManageAccountsPressed() {
  // TODO:
}
