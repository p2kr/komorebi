import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MiscSettings extends HookWidget {
  const MiscSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final packageInfoFuture = useMemoized(() => PackageInfo.fromPlatform(), []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Miscellaneous",
          style: context.textTheme.titleLarge?.copyWith(
            // fontWeight: FontWeight.bold,
            fontFamily: context.fontSerif,
          ),
        ),
        FutureBuilder(
          future: packageInfoFuture,
          builder: (context, asyncSnapshot) {
            return ListTile(
              title: Text("About $APP_NAME"),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationIcon: CircleAvatar(
                    child: Image.asset("assets/icons/logo.png"),
                  ),
                  applicationName: asyncSnapshot.data?.appName,
                  applicationVersion: asyncSnapshot.data?.version,
                  children: [Text(S.of(context).appDescription)],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
