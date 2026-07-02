part of 'theme.dart';

/// -----------------------------------
/// 1. Obsidian Fonts
/// -----------------------------------
abstract class ObsidianFonts {
  static const String serif = 'Playfair Display';
  static const String sans = 'Inter';
  static const String mono = 'JetBrains Mono';
}

/// -----------------------------------
/// 2. Obsidian Colors
/// -----------------------------------
abstract class ObsidianColors {
  // --- Dark Mode ---
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkSurfaceVariant = Color(0xFF0D0D0D);
  static const Color darkBorder = Color(0xFF222222);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF666666);

  // --- Light Mode ---
  static const Color lightBackground = Color(0xFFF7F7F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F0F0);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightTextPrimary = Color(0xFF111111);
  static const Color lightTextSecondary = Color(0xFF666666);

  // --- Accents & Semantics ---
  static const Color malBlue = Color(0xFF2E51A2);
  static const Color successGreen = Color(0xFF4ADE80);
  static const Color errorRed = Color(0xFFF87171);
  static const Color warningYellow = Color(0xFFFACC15);
}

/// -----------------------------------
/// 3. Obsidian Theme
/// -----------------------------------
class ObsidianTheme {
  // --- Shared Geometry ---
  static const double _borderRadius = 4.0;
  static const Radius _radiusCirc = Radius.circular(_borderRadius);

  static final RoundedRectangleBorder _cardShape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(_radiusCirc),
  );

  // --- Typography Builder (Thinner Weights for Archival Look) ---
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      // Serif Headers (w400 for elegant look)
      displayLarge: TextStyle(
        fontFamily: ObsidianFonts.serif,
        color: primary,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: TextStyle(
        fontFamily: ObsidianFonts.serif,
        color: primary,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: TextStyle(
        fontFamily: ObsidianFonts.serif,
        color: primary,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        fontFamily: ObsidianFonts.serif,
        color: primary,
        fontWeight: FontWeight.w400,
      ),
      headlineMedium: TextStyle(
        fontFamily: ObsidianFonts.serif,
        color: primary,
        fontWeight: FontWeight.w400,
      ),
      headlineSmall: TextStyle(
        fontFamily: ObsidianFonts.serif,
        color: primary,
        fontWeight: FontWeight.w400,
        fontSize: 18,
      ),
      titleLarge: TextStyle(
        fontFamily: ObsidianFonts.serif,
        color: primary,
        fontWeight: FontWeight.w400,
        fontSize: 16,
      ),

      // Sans UI Text (w300 Light for descriptions, w400 for titles)
      bodyLarge: TextStyle(
        fontFamily: ObsidianFonts.sans,
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w300,
      ),
      bodyMedium: TextStyle(
        fontFamily: ObsidianFonts.sans,
        color: primary,
        fontSize: 14,
        fontWeight: FontWeight.w300,
      ),
      bodySmall: TextStyle(
        fontFamily: ObsidianFonts.sans,
        color: secondary,
        fontSize: 12,
        fontWeight: FontWeight.w300,
      ),
      titleMedium: TextStyle(
        fontFamily: ObsidianFonts.sans,
        color: primary,
        fontWeight: FontWeight.w400,
      ),
      titleSmall: TextStyle(
        fontFamily: ObsidianFonts.sans,
        color: primary,
        fontWeight: FontWeight.w400,
      ),

      // Mono Labels (w400 instead of bold)
      labelLarge: TextStyle(
        fontFamily: ObsidianFonts.mono,
        color: primary,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
      ),
      labelMedium: TextStyle(
        fontFamily: ObsidianFonts.mono,
        color: secondary,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
      ),
      labelSmall: TextStyle(
        fontFamily: ObsidianFonts.mono,
        color: secondary,
        fontWeight: FontWeight.w400,
        fontSize: 10,
        letterSpacing: 1.5,
      ),
    );
  }

  // --- Shared Input Decoration ---
  static InputDecorationTheme _buildInputDecoration(
    Color fill,
    Color border,
    Color textSecondary,
    Color focusBorder,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(
        fontFamily: ObsidianFonts.sans,
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w300,
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(_radiusCirc),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(_radiusCirc),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(_radiusCirc),
        borderSide: BorderSide(color: focusBorder),
      ),
    );
  }

  // ==========================================
  // DARK THEME
  // ==========================================
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ObsidianColors.darkBackground,
    primaryColor: ObsidianColors.malBlue,
    dividerColor: ObsidianColors.darkBorder,
    colorScheme: const ColorScheme.dark(
      primary: ObsidianColors.malBlue,
      secondary: ObsidianColors.darkSurfaceVariant,
      surface: ObsidianColors.darkSurface,
      error: ObsidianColors.errorRed,
      onPrimary: Colors.white,
      onSurface: ObsidianColors.darkTextPrimary,
    ),
    textTheme: _buildTextTheme(
      ObsidianColors.darkTextPrimary,
      ObsidianColors.darkTextSecondary,
    ),

    // Components
    appBarTheme: const AppBarTheme(
      backgroundColor: ObsidianColors.darkSurfaceVariant,
      elevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(color: ObsidianColors.darkBorder, width: 1),
      ),
      iconTheme: IconThemeData(color: ObsidianColors.darkTextPrimary, size: 20),
    ),
    cardTheme: CardThemeData(
      color: ObsidianColors.darkSurface,
      elevation: 0,
      shape: _cardShape.copyWith(
        side: const BorderSide(color: ObsidianColors.darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        shape: _cardShape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: ObsidianFonts.mono,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ObsidianColors.darkTextPrimary,
        backgroundColor: ObsidianColors.darkSurface,
        side: const BorderSide(color: ObsidianColors.darkBorder),
        shape: _cardShape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: ObsidianFonts.mono,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
      ),
    ),
    inputDecorationTheme: _buildInputDecoration(
      ObsidianColors.darkBackground,
      ObsidianColors.darkBorder,
      ObsidianColors.darkTextSecondary,
      const Color(0xFF444444),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ObsidianColors.darkSurfaceVariant,
      selectedItemColor: Colors.white,
      unselectedItemColor: ObsidianColors.darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );

  // ==========================================
  // LIGHT THEME
  // ==========================================
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: ObsidianColors.lightBackground,
    primaryColor: ObsidianColors.malBlue,
    dividerColor: ObsidianColors.lightBorder,
    colorScheme: const ColorScheme.light(
      primary: ObsidianColors.malBlue,
      secondary: ObsidianColors.lightSurfaceVariant,
      surface: ObsidianColors.lightSurface,
      error: ObsidianColors.errorRed,
      onPrimary: Colors.white,
      onSurface: ObsidianColors.lightTextPrimary,
    ),
    textTheme: _buildTextTheme(
      ObsidianColors.lightTextPrimary,
      ObsidianColors.lightTextSecondary,
    ),

    // Components
    appBarTheme: const AppBarTheme(
      backgroundColor: ObsidianColors.lightSurface,
      elevation: 0,
      centerTitle: false,
      shape: Border(
        bottom: BorderSide(color: ObsidianColors.lightBorder, width: 1),
      ),
      iconTheme: IconThemeData(
        color: ObsidianColors.lightTextPrimary,
        size: 20,
      ),
    ),
    cardTheme: CardThemeData(
      color: ObsidianColors.lightSurface,
      elevation: 0,
      shape: _cardShape.copyWith(
        side: const BorderSide(color: ObsidianColors.lightBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ObsidianColors.lightTextPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: _cardShape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: ObsidianFonts.mono,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ObsidianColors.lightTextPrimary,
        backgroundColor: ObsidianColors.lightSurface,
        side: const BorderSide(color: ObsidianColors.lightBorder),
        shape: _cardShape,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: ObsidianFonts.mono,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
      ),
    ),
    inputDecorationTheme: _buildInputDecoration(
      ObsidianColors.lightBackground,
      ObsidianColors.lightBorder,
      ObsidianColors.lightTextSecondary,
      const Color(0xFFBBBBBB),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ObsidianColors.lightSurface,
      selectedItemColor: ObsidianColors.lightTextPrimary,
      unselectedItemColor: ObsidianColors.lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w400),
    ),
  );
}
