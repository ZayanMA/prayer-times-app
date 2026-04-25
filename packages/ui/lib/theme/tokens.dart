import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadii {
  const AppRadii._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
}

class AppColors {
  const AppColors._();

  static const Color brand = Color(0xFF0F766E);
  static const Color brandDark = Color(0xFF064E3B);
  static const Color accent = Color(0xFFD4A24C);

  static const Color inkLight = Color(0xFF111827);
  static const Color mutedLight = Color(0xFF6B7280);
  static const Color surfaceLight = Color(0xFFF7F5EE);
  static const Color panelLight = Color(0xFFFFFFFF);
  static const Color lineLight = Color(0xFFE7E2D5);

  static const Color inkDark = Color(0xFFF1F5F4);
  static const Color mutedDark = Color(0xFF9CA3AF);
  static const Color surfaceDark = Color(0xFF0B1220);
  static const Color panelDark = Color(0xFF111A2C);
  static const Color lineDark = Color(0xFF1F2A3F);
}

class AppGradients {
  const AppGradients._();

  static LinearGradient heroForTime(DateTime time, {bool dark = false}) {
    final hour = time.hour;
    if (hour < 5) {
      return dark ? _nightDark : _night;
    } else if (hour < 9) {
      return dark ? _dawnDark : _dawn;
    } else if (hour < 16) {
      return dark ? _dayDark : _day;
    } else if (hour < 19) {
      return dark ? _duskDark : _dusk;
    }
    return dark ? _nightDark : _night;
  }

  static const _dawn = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB88C), Color(0xFFDE6262)],
  );
  static const _dawnDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8B3A3A), Color(0xFF42184B)],
  );
  static const _day = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF134E4A)],
  );
  static const _dayDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0B5E58), Color(0xFF0A2E2C)],
  );
  static const _dusk = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFF7C2D12)],
  );
  static const _duskDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C5210), Color(0xFF411B11)],
  );
  static const _night = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
  );
  static const _nightDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2A5C), Color(0xFF050816)],
  );
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    );

    final baseText = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -1.0,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: baseText.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: isDark ? AppColors.panelDark : AppColors.panelLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.lineLight,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.panelDark : AppColors.panelLight,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(
            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? AppColors.panelDark : AppColors.panelLight,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
        ),
        unselectedIconTheme: IconThemeData(
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
        unselectedLabelTextStyle: textTheme.labelLarge?.copyWith(
          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor:
            isDark ? AppColors.inkDark : AppColors.inkLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: isDark ? AppColors.inkDark : AppColors.inkLight,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        side: BorderSide(
          color: isDark ? AppColors.lineDark : AppColors.lineLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.panelDark : AppColors.panelLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.lineLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.lineLight,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.lineDark : AppColors.lineLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
