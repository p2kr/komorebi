import 'package:flutter/material.dart';

part 'obsidian_theme.dart';

extension ThemeContextExtension on BuildContext {
  // Shortcut for TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Shortcut for ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
