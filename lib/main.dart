import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/providers/common_providers.dart';
import 'package:komorebi/screens/home.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:komorebi/utils/init.dart';
import 'package:komorebi/utils/talker.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  talker.info("app starting...");

  try {
    await doInitialConfigurations(args);
  } catch (e, stack) {
    talker.error("Exception in doInitialConfigurations: ", e, stack);
  }

  talker.info("app started.");

  runApp(
    ProviderScope(
      observers: [TalkerRiverpodObserver(talker: talker)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      locale: locale,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        LocaleNamesLocalizationsDelegate(),
      ],
      supportedLocales: S.delegate.supportedLocales,
      title: APP_NAME,
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      home: const HomePage(),
    );
  }
}
