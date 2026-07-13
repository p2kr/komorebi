import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/providers/common_providers.dart';

class SettingsButton extends ConsumerWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: "Settings",
      child: SizedBox(
        height: 32,
        child: IconButton(
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const SettingsDialog(),
            );
          },
          icon: const Icon(Icons.settings_outlined),
        ),
      ),
    );
  }
}

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapTitles = ref.watch(swapAlternateTitleProvider);
    return AlertDialog(
      title: const Text("Settings"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text("Swap Alternate Title"),
            subtitle: const Text(
              "Show english title as main title when available",
            ),
            value: swapTitles,
            onChanged: (val) {
              ref.read(swapAlternateTitleProvider.notifier).toggle();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("CLOSE"),
        ),
      ],
    );
  }
}
