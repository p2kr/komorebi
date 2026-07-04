// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `AUTOMATED CRAWLER & SYNC ENGINE`
  String get automatedCrawlerSyncEngine {
    return Intl.message(
      'AUTOMATED CRAWLER & SYNC ENGINE',
      name: 'automatedCrawlerSyncEngine',
      desc: '',
      args: [],
    );
  }

  /// `Diagnostics`
  String get diagnostics {
    return Intl.message('Diagnostics', name: 'diagnostics', desc: '', args: []);
  }

  /// `Check New Episodes`
  String get checkNewEpisodes {
    return Intl.message(
      'Check New Episodes',
      name: 'checkNewEpisodes',
      desc: '',
      args: [],
    );
  }

  /// `System Diagnostics & Logging Vault`
  String get systemDiagnosticsLoggingVault {
    return Intl.message(
      'System Diagnostics & Logging Vault',
      name: 'systemDiagnosticsLoggingVault',
      desc: '',
      args: [],
    );
  }

  /// `CLOSE`
  String get close {
    return Intl.message('CLOSE', name: 'close', desc: '', args: []);
  }

  /// `LEVEL`
  String get level {
    return Intl.message('LEVEL', name: 'level', desc: '', args: []);
  }

  /// `CATEGORY`
  String get category {
    return Intl.message('CATEGORY', name: 'category', desc: '', args: []);
  }

  /// `Buffer Capacity`
  String get bufferCapacity {
    return Intl.message(
      'Buffer Capacity',
      name: 'bufferCapacity',
      desc: '',
      args: [],
    );
  }

  /// `entries`
  String get entries {
    return Intl.message('entries', name: 'entries', desc: '', args: []);
  }

  /// `System`
  String get system {
    return Intl.message('System', name: 'system', desc: '', args: []);
  }

  /// `ONLINE`
  String get online {
    return Intl.message('ONLINE', name: 'online', desc: '', args: []);
  }

  /// `No log entries recorded. Initiate MAL synchronizations or crawls to stream logs.`
  String get noLogEntriesRecorded {
    return Intl.message(
      'No log entries recorded. Initiate MAL synchronizations or crawls to stream logs.',
      name: 'noLogEntriesRecorded',
      desc: '',
      args: [],
    );
  }

  /// `OTHER CONNECTED PROFILES`
  String get otherConnectedProfiles {
    return Intl.message(
      'OTHER CONNECTED PROFILES',
      name: 'otherConnectedProfiles',
      desc: '',
      args: [],
    );
  }

  /// `DISCONNECT ACTIVE PROFILE`
  String get disconnectActiveProfile {
    return Intl.message(
      'DISCONNECT ACTIVE PROFILE',
      name: 'disconnectActiveProfile',
      desc: '',
      args: [],
    );
  }

  /// `QUICK SANDBOX LINK`
  String get quickSandboxLink {
    return Intl.message(
      'QUICK SANDBOX LINK',
      name: 'quickSandboxLink',
      desc: '',
      args: [],
    );
  }

  /// `LINK ANOTHER MAL (OAUTH)`
  String get linkAnotherMalOauth {
    return Intl.message(
      'LINK ANOTHER MAL (OAUTH)',
      name: 'linkAnotherMalOauth',
      desc: '',
      args: [],
    );
  }

  /// `Connected since`
  String get connectedSince {
    return Intl.message(
      'Connected since',
      name: 'connectedSince',
      desc: '',
      args: [],
    );
  }

  /// `MYANIMELIST OAUTH`
  String get myanimelistOauth {
    return Intl.message(
      'MYANIMELIST OAUTH',
      name: 'myanimelistOauth',
      desc: '',
      args: [],
    );
  }

  /// `SANDBOX`
  String get sandbox {
    return Intl.message('SANDBOX', name: 'sandbox', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'es'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
