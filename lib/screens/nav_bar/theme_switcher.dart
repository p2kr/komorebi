import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/providers/common_providers.dart';

class ThemeSwitcher extends ConsumerWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 32,
      child: Center(
        child: Switch(
          value: themeMode == ThemeMode.light,
          mouseCursor: SystemMouseCursors.click,
          onChanged: (value) {
            if (value) {
              ref.read(themeModeProvider.notifier).update(ThemeMode.light);
            } else {
              ref.read(themeModeProvider.notifier).update(ThemeMode.dark);
            }
          },
          activeThumbColor: colorScheme.onPrimary,
          inactiveThumbColor: colorScheme.onSurfaceVariant,
          activeTrackColor: colorScheme.primary,
          inactiveTrackColor: colorScheme.surfaceContainerHighest,
          thumbIcon: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Icon(Icons.light_mode_outlined, color: colorScheme.primary);
            }
            return Icon(
              Icons.dark_mode_outlined,
              color: colorScheme.surfaceContainerHighest,
            );
          }),
        ),
      ),
    );
  }
}
