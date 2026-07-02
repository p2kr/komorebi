import 'package:flutter/material.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/constants.dart';

AppBar customAppBar(BuildContext context) {
  return AppBar(
    title: Row(
      children: [
        Column(
          crossAxisAlignment: .start,
          children: [
            Text(APP_NAME, style: context.textTheme.headlineMedium),
            Text(
              S.of(context).automatedCrawlerSyncEngine.toUpperCase(),
              style: context.textTheme.labelSmall,
            ),
          ],
        ),
        Spacer(),
        Row(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: onDiagnosticsPressed,
              icon: Icon(Icons.monitor_heart_outlined),
              label: Text(S.of(context).diagnostics),
            ),
            OutlinedButton.icon(
              onPressed: onCheckNewEpisodePressed,
              icon: Icon(Icons.notifications_none),
              label: Text(S.of(context).checkNewEpisodes),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(padding: .zero),
              onPressed: onManageAccountsPressed,
              child: Icon(Icons.manage_accounts_outlined),
            ),
          ],
        ),
      ],
    ),
    leading: Image.asset("assets/icons/logo.png", fit: .contain),
  );
}

void onDiagnosticsPressed() {
  // TODO:
}

void onCheckNewEpisodePressed() {
  // TODO:
}

void onManageAccountsPressed() {
  // TODO:
}
