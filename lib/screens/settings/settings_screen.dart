import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:komorebi/screens/settings/sections/appearance_settings.dart';
import 'package:komorebi/screens/settings/sections/general_settings.dart';
import 'package:komorebi/themes/theme.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          GeneralSettings(),
          SizedBox(height: 16),
          AppearanceSettings(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
