import 'package:flutter/material.dart';
import 'package:komorebi/screens/settings/sections/appearance_settings.dart';
import 'package:komorebi/screens/settings/sections/general_settings.dart';
import 'package:komorebi/screens/settings/sections/misc_settings.dart';
import 'package:komorebi/themes/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          GeneralSettings(),
          SizedBox(height: 16),
          AppearanceSettings(),
          SizedBox(height: 16),
          MiscSettings(),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
