import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/utils.dart';
import 'package:super_tooltip/super_tooltip.dart';

class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.appearance,
          style: context.textTheme.titleLarge?.copyWith(
            // fontWeight: FontWeight.bold,
            fontFamily: context.fontSerif,
          ),
        ),
        const SizedBox(height: 16),

        // Theme switcher
        ListTile(
          title: Text(s.theme),
          subtitle: Text(s.toggleBetweenLightAndDarkMode),
          trailing: Switch(
            value: themeMode == ThemeMode.light,
            mouseCursor: SystemMouseCursors.click,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
            activeThumbColor: colorScheme.onPrimary,
            inactiveThumbColor: colorScheme.onSurfaceVariant,
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surfaceContainerHighest,
            thumbIcon: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Icon(
                  Icons.light_mode_outlined,
                  color: colorScheme.primary,
                );
              }
              return Icon(
                Icons.dark_mode_outlined,
                color: colorScheme.surfaceContainerHighest,
              );
            }),
          ),
        ),

        // Language switcher
        ListTile(title: Text(s.language), trailing: LanguageSwitcher()),
      ],
    );
  }
}

class LanguageSwitcher extends HookConsumerWidget {
  LanguageSwitcher({super.key});

  final tooltipController = SuperTooltipController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    useEffect(() => tooltipController.dispose, []);

    return SuperTooltip(
      constraints: BoxConstraints(maxWidth: 200),
      controller: tooltipController,
      content: ListView(
        shrinkWrap: true,
        padding: .all(2),
        children: [
          for (final supportedLocale in S.delegate.supportedLocales)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: locale == supportedLocale
                    ? BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    selected: locale == supportedLocale,
                    title: Localizations.override(
                      context: context,
                      locale: supportedLocale,
                      child: Builder(
                        builder: (context) {
                          final localeNames = LocaleNames.of(context);
                          final text =
                              localeNames!.data.containsKey(
                                supportedLocale.languageCode,
                              )
                              ? localeNames.nameOf(
                                  supportedLocale.languageCode,
                                )!
                              : supportedLocale.languageCode;

                          return Center(
                            child: Text(text.toLocalizedCapitalized()),
                          );
                        },
                      ),
                    ),
                    onTap: () {
                      ref.read(localeProvider.notifier).update(supportedLocale);
                      tooltipController.hideTooltip();
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: () {
          tooltipController.showTooltip();
        },
        icon: Icon(Icons.language_outlined),
        label: Text(
          locale.languageCode.toUpperCase(),
          style: context.textTheme.bodyMedium?.copyWith(fontWeight: .bold),
        ),
        style: OutlinedButton.styleFrom(
          shape: StadiumBorder(side: BorderSide()),
          padding: .symmetric(horizontal: 8, vertical: 0),
        ),
      ),
    );
  }
}
