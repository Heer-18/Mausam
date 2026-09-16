import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundStart = Color(0xFF090D16);
  static const Color backgroundEnd = Color(0xFF111827);
  static const Color backgroundDark = Color(0xFF090D16);
  static const Color surface = Color(0xFF131315);
  static const Color surfaceContainer = Color(0xFF1F1F21);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2C);
  static const Color surfaceVariant = Color(0xFF353437);

  static const Color onSurface = Color(0xFFE4E2E4);
  static const Color onSurfaceVariant = Color(0xFFC1C6D7);
  static const Color onSurfaceDim = Color(0xFF8B90A0);

  static const Color primary = Color(0xFFADC6FF);
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color primaryContainer = Color(0xFF4B8EFF);
  static const Color onPrimary = Color(0xFF002E69);

  static const Color electricCyan = Color(0xFF06B6D4);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color alertRed = Color(0xFFEF4444);
  static const Color agriEmerald = Color(0xFF10B981);
  static const Color fitnessViolet = Color(0xFF8B5CF6);

  static const Color glassFill = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassBorderBright = Color(0x33FFFFFF);
  static const Color glassHighlight = Color(0x26ADC6FF);

  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF090D16),
      Color(0xFF0D1322),
      Color(0xFF111827),
    ],
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x1FADC6FF),
      Color(0x0A8382FF),
      Color(0x08FFFFFF),
    ],
  );

  static const LinearGradient aiGlowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x4D4B8EFF),
      Color(0x338B5CF6),
      Color(0x1A06B6D4),
    ],
  );
}

class AppTypography {
  static const TextStyle displayTemp = TextStyle(
    fontSize: 88,
    fontWeight: FontWeight.w200,
    letterSpacing: -2.5,
    color: Colors.white,
    height: 1.0,
    shadows: [
      Shadow(
        color: Color(0x33000000),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  );

  static const TextStyle headlineLg = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Colors.white,
  );

  static const TextStyle headlineMd = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  static const TextStyle titleMd = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: Color(0xFFF1F5F9),
    height: 1.4,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: Color(0xFFE2E8F0),
  );

  static const TextStyle labelCaps = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: Color(0xFFCBD5E1),
  );

  static const TextStyle dataMono = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundStart,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.electricCyan,
        surface: AppColors.surface,
        error: AppColors.alertRed,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.onSurface,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
