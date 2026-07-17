import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/themes/theme.dart';

class GeneralSettings extends ConsumerWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final swapTitles = ref.watch(swapAlternateTitleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.generalSettings,
          style: context.textTheme.titleLarge?.copyWith(
            // fontWeight: FontWeight.bold,
            fontFamily: context.fontSerif,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text(s.swapAlternateTitle),
          subtitle: Text(s.showEnglishTitleAsMainTitleWhenAvailable),
          value: swapTitles,
          onChanged: (_) =>
              ref.read(swapAlternateTitleProvider.notifier).toggle(),
        ),
      ],
    );
  }
}
