import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:popover/popover.dart';

class LangSwitcher extends ConsumerWidget {
  const LangSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Tooltip(
      message: S.of(context).selectLanguage,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          height: 32,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            mouseCursor: SystemMouseCursors.click,
            onTap: () {
              showPopover<Locale>(
                context: context,
                bodyBuilder: (context) => const _LangPopoverContent(),
                direction: PopoverDirection.top,
                arrowWidth: 16,
                arrowHeight: 10,
                radius: 12,
                backgroundColor: theme.cardColor,
                barrierColor: theme.shadowColor.withValues(alpha: 0.3),
                shadow: [
                  BoxShadow(
                    color: colorScheme.outline.withValues(alpha: 0.35),
                    blurRadius: 0,
                    spreadRadius:
                        1, // 1px clean border outline around popover body AND arrow from theme
                  ),
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
                width: 130,
              );
            },
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.language, size: 18, color: colorScheme.onSurface),
                  const SizedBox(width: 6),
                  Text(
                    currentLocale.languageCode.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangPopoverContent extends ConsumerWidget {
  const _LangPopoverContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final supportedLocales = S.delegate.supportedLocales;

    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: supportedLocales.map((locale) {
          final isSelected = currentLocale.languageCode == locale.languageCode;

          // Auto-fetch native language name from CLDR database
          final nativeName =
              LocaleNamesLocalizationsDelegate.nativeLocaleNames[locale
                  .languageCode] ??
              locale.languageCode.toUpperCase();
          final label = nativeName.isNotEmpty
              ? '${nativeName[0].toUpperCase()}${nativeName.substring(1)}'
              : nativeName;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                ref.read(localeProvider.notifier).update(locale);
                Navigator.of(context).pop();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: isSelected
                    ? BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
