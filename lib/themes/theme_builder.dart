import 'package:flutter/material.dart';

/// A lightweight, highly configurable Material 3 theme generator.
///
/// Automatically builds perfectly matched light and dark themes from a single
/// seed color, enforcing strict typography rules and consistent UI shapes.
///
/// ### Quick Start
/// ```dart
/// final appTheme = AppThemeBuilder();
///
/// MaterialApp(
///   themeMode: ThemeMode.system,
///   theme: appTheme.lightTheme,
///   darkTheme: appTheme.darkTheme,
/// )
/// ```
///
/// ### Typography Mapping
/// * **Serif** (`fontSerif`): Displays and Headlines.
/// * **Sans** (`fontSans`): Titles and Body text.
/// * **Mono** (`fontMono`): Labels, buttons, and captions.
class ThemeBuilder {
  /// The base color used to calculate the entire application palette.
  final Color seedColor;

  /// The Material 3 algorithm used to generate the palette.
  ///
  /// **Note:** `monochrome` strips all color. To see vibrant seed colors
  /// (e.g., Deep Purple), change this to `DynamicSchemeVariant.tonalSpot`.
  final DynamicSchemeVariant variant;

  /// The border radius applied to all buttons (Elevated, Filled, Outlined, Text).
  /// Set to `0.0` for a Brutalist/sharp look, or `12.0` for a modern pill look.
  final double buttonRadius;

  /// The border radius applied to all dialog windows.
  /// Proportional scaling: keep this larger than [buttonRadius] for visual harmony.
  final double dialogRadius;

  /// Applied to Display and Headline text styles. Best for elegant titles.
  final String fontSerif;

  /// Applied to Title and Body text styles. Acts as the app's default fallback font.
  final String fontSans;

  /// Applied to Label text styles. Best for buttons, captions, and code.
  final String fontMono;

  /// Creates a customized Material 3 theme engine.
  ///
  /// Defaults to a minimalist, black-and-white monochrome design with
  /// subtle 4px button curves and proportional 8px dialog curves.
  ThemeBuilder({
    this.seedColor = Colors.black,
    this.variant = DynamicSchemeVariant.monochrome,
    this.buttonRadius = 4.0,
    this.dialogRadius = 8.0,
    this.fontSerif = 'Playfair Display',
    this.fontSans = 'Inter',
    this.fontMono = 'JetBrains Mono',
  });

  // --- Typography ---
  TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      // SERIF: Displays & Headlines
      displayLarge: base.displayLarge?.copyWith(fontFamily: fontSerif),
      displayMedium: base.displayMedium?.copyWith(fontFamily: fontSerif),
      displaySmall: base.displaySmall?.copyWith(fontFamily: fontSerif),
      headlineLarge: base.headlineLarge?.copyWith(fontFamily: fontSerif),
      headlineMedium: base.headlineMedium?.copyWith(fontFamily: fontSerif),
      headlineSmall: base.headlineSmall?.copyWith(fontFamily: fontSerif),

      // SANS: Titles & Body Text
      titleLarge: base.titleLarge?.copyWith(fontFamily: fontSans),
      titleMedium: base.titleMedium?.copyWith(fontFamily: fontSans),
      titleSmall: base.titleSmall?.copyWith(fontFamily: fontSans),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: fontSans),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: fontSans),
      bodySmall: base.bodySmall?.copyWith(fontFamily: fontSans),

      // MONO: Labels, Buttons, and Captions
      labelLarge: base.labelLarge?.copyWith(fontFamily: fontMono),
      labelMedium: base.labelMedium?.copyWith(fontFamily: fontMono),
      labelSmall: base.labelSmall?.copyWith(fontFamily: fontMono),
    );
  }

  // --- Core Generator ---
  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: variant,
    );

    final base = brightness == Brightness.light
        ? ThemeData.light()
        : ThemeData.dark();

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    final dialogShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dialogRadius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontSans,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _buildTextTheme(base.textTheme),

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),

      dialogTheme: DialogThemeData(shape: dialogShape),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: buttonShape),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: buttonShape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape),
      ),
    );
  }

  /// Generates the properly configured Light theme.
  ThemeData get lightTheme => _buildTheme(Brightness.light);

  /// Generates the properly configured Dark theme.
  ThemeData get darkTheme => _buildTheme(Brightness.dark);
}
