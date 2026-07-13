import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/services/database.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/themes/theme_builder.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'common_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase db(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
}

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    return ThemeMode.dark;
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void update(ThemeMode mode) {
    state = mode;
  }
}

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() {
    final systemCode = Intl.defaultLocale?.split('_').first;
    if (systemCode != null) {
      for (final locale in S.delegate.supportedLocales) {
        if (locale.languageCode == systemCode) {
          return locale;
        }
      }
    }
    return const Locale('en');
  }

  void update(Locale locale) {
    state = locale;
  }
}

@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeBuilder build() {
    return defaultMonochromeTheme;
  }

  void updateTheme(ThemeBuilder newTheme) {
    state = newTheme;
  }

  void resetTheme() {
    state = defaultMonochromeTheme;
  }
}

@Riverpod(keepAlive: true)
class SwapAlternateTitleNotifier extends _$SwapAlternateTitleNotifier {
  @override
  bool build() {
    return false;
  }

  Future<void> load() async {
    final database = ref.read(dbProvider);
    final config = await database.configsDao.getConfig(Settings.SWAP_ALTERNATE_TITLE.name);
    if (config != null) {
      state = config.configValue == 'true';
    }
  }

  void toggle() {
    state = !state;
    final database = ref.read(dbProvider);
    database.configsDao.setConfig(Settings.SWAP_ALTERNATE_TITLE.name, state.toString());
  }
}
