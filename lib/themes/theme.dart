import 'package:flutter/material.dart';
import 'package:komorebi/themes/theme_builder.dart';

/// Shortcuts for BuildContext
extension ThemeContextExtension on BuildContext {
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

////////////
// THEMES //
////////////

/// Uses black seed. Fonts are Playfair Display, Inter and Jetbrains Mono
final defaultMonochromeTheme = ThemeBuilder();
