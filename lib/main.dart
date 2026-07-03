import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:komorebi/intl/generated/l10n.dart';
import 'package:komorebi/screens/home.dart';
import 'package:komorebi/themes/theme.dart';
import 'package:komorebi/utils/constants.dart';
import 'package:komorebi/utils/init.dart';
import 'package:komorebi/utils/talker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  talker.info("app starting...");

  try {
    await doInitialConfigurations();
  } catch (e, stack) {
    talker.error("Exception in doInitialConfigurations: ", e, stack);
  }

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      // locale: Locale("es"),
      title: APP_NAME,
      theme: ObsidianTheme.lightTheme,
      darkTheme: ObsidianTheme.darkTheme,
      // themeMode: .light,
      home: const HomePage(),
    );
  }
}
