import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prayer_times_core/core.dart';

import 'tokens.dart';

// ─────────────────────────────────────────────────────────────
// Direction A — Almanac
// Paper-toned, monospaced, scholarly broadsheet
// ─────────────────────────────────────────────────────────────
class ATokens {
  const ATokens._();

  static const paper    = Color(0xFFF1ECE0);
  static const paperAlt = Color(0xFFE9E2D1);
  static const ink      = Color(0xFF1A1814);
  static const ink60    = Color(0x991A1814);
  static const ink40    = Color(0x661A1814);
  static const ink20    = Color(0x2E1A1814);
  static const ink08    = Color(0x141A1814);
  static const rule     = Color(0xFF2A2620);
  static const accent   = Color(0xFF9A3324);

  static TextStyle mono({
    double size = 13,
    FontWeight w = FontWeight.w400,
    Color? color,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: w,
        color: color ?? ink,
        letterSpacing: letterSpacing,
      );

  static TextStyle serif({
    double size = 16,
    FontWeight w = FontWeight.w400,
    bool italic = false,
    Color? color,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.spectral(
        fontSize: size,
        fontWeight: w,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color ?? ink,
        letterSpacing: letterSpacing,
      );
}

// ─────────────────────────────────────────────────────────────
// Direction B — Calligraphic
// Dark bg + gold, Arabic calligraphy hero, Cormorant display
// ─────────────────────────────────────────────────────────────
class BTokens {
  const BTokens._();

  static const bg      = Color(0xFF0C0A08);
  static const bgAlt   = Color(0xFF15110D);
  static const panel   = Color(0xFF1A1612);
  static const ink     = Color(0xFFF3EDE1);
  static const ink60   = Color(0x99F3EDE1);
  static const ink40   = Color(0x66F3EDE1);
  static const ink20   = Color(0x2EF3EDE1);
  static const gold    = Color(0xFFC9A35A);
  static const goldDim = Color(0xFF8A6F3A);

  static TextStyle arabic({double size = 22, Color? color}) =>
      GoogleFonts.amiri(fontSize: size, color: color ?? gold);

  static TextStyle display({
    double size = 17,
    bool italic = false,
    Color? color,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: color ?? ink,
        letterSpacing: letterSpacing,
      );

  static TextStyle body({double size = 13, Color? color, double letterSpacing = 0}) =>
      GoogleFonts.inter(fontSize: size, color: color ?? ink, letterSpacing: letterSpacing);
}

// ─────────────────────────────────────────────────────────────
// Direction C — Celestial
// Sky gradients, Fraunces serif, frosted glass cards
// ─────────────────────────────────────────────────────────────
class CTokens {
  const CTokens._();

  static const gold  = Color(0xFFFFD96E);
  static const ink   = Colors.white;
  static const ink70 = Color(0xB3FFFFFF);
  static const ink40 = Color(0x66FFFFFF);
  static const ink20 = Color(0x33FFFFFF);
  static const ink10 = Color(0x1AFFFFFF);

  static TextStyle serif({
    double size = 16,
    FontWeight w = FontWeight.w300,
    Color? color,
    bool italic = false,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: w,
        color: color ?? Colors.white,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        letterSpacing: letterSpacing,
      );

  static TextStyle mono({double size = 13, Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, color: color ?? Colors.white);

  static TextStyle body({double size = 13, Color? color, double letterSpacing = 0}) =>
      GoogleFonts.inter(fontSize: size, color: color ?? Colors.white, letterSpacing: letterSpacing);

  // Sky gradient LUT — matches skyGradient() in direction-c-celestial.jsx
  static LinearGradient skyGradient(DateTime now) {
    final frac = (now.hour + now.minute / 60.0) / 24.0;
    if (frac < 0.18) {
      return const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF050817), Color(0xFF0A0E2A), Color(0xFF1A1A4A)],
        stops: [0, 0.5, 1],
      );
    }
    if (frac < 0.32) {
      return const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF1A2A4A), Color(0xFFC75E85), Color(0xFFF5B876)],
        stops: [0, 0.6, 1],
      );
    }
    if (frac < 0.55) {
      return const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF6CB6E8), Color(0xFFB9D8F0), Color(0xFFF0E9D8)],
        stops: [0, 0.6, 1],
      );
    }
    if (frac < 0.78) {
      return const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF4A8EC8), Color(0xFFF5B876), Color(0xFFE58A5E)],
        stops: [0, 0.6, 1],
      );
    }
    if (frac < 0.88) {
      return const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF5A3A7A), Color(0xFFC75E85), Color(0xFFE58A5E)],
        stops: [0, 0.5, 1],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [Color(0xFF050817), Color(0xFF0A0E2A), Color(0xFF1A1A4A)],
      stops: [0, 0.5, 1],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Per-direction ThemeData factory
// ─────────────────────────────────────────────────────────────
extension DirectionTheme on AppTheme {
  static ThemeData forDirection(
      AppDesignDirection direction, Brightness brightness) {
    return switch (direction) {
      AppDesignDirection.almanac      => _buildAlmanac(brightness),
      AppDesignDirection.calligraphic => _buildCalligraphic(brightness),
      AppDesignDirection.celestial    => _buildCelestial(brightness),
    };
  }

  static ThemeData _buildAlmanac(Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: ATokens.accent,
      onPrimary: ATokens.paper,
      secondary: ATokens.ink,
      onSecondary: ATokens.paper,
      error: const Color(0xFFB00020),
      onError: Colors.white,
      surface: ATokens.paper,
      onSurface: ATokens.ink,
      surfaceContainerHighest: ATokens.paperAlt,
      outline: ATokens.rule,
    );

    final baseText = GoogleFonts.jetBrainsMonoTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ATokens.paper,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: ATokens.paper,
        foregroundColor: ATokens.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: ATokens.serif(size: 20, italic: true),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: ATokens.paperAlt,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: ATokens.ink20,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: ATokens.paper,
        indicatorColor: ATokens.ink08,
        labelTextStyle: WidgetStateProperty.all(ATokens.mono(size: 10)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: ATokens.ink);
          }
          return const IconThemeData(color: ATokens.ink40);
        }),
        shadowColor: ATokens.ink20,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: ATokens.paper,
        indicatorColor: ATokens.ink08,
        selectedIconTheme: const IconThemeData(color: ATokens.ink),
        unselectedIconTheme: const IconThemeData(color: ATokens.ink40),
        selectedLabelTextStyle: ATokens.mono(size: 12),
        unselectedLabelTextStyle: ATokens.mono(size: 12, color: ATokens.ink40),
      ),
    );
  }

  static ThemeData _buildCalligraphic(Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: BTokens.gold,
      onPrimary: BTokens.bg,
      secondary: BTokens.goldDim,
      onSecondary: BTokens.bg,
      error: const Color(0xFFCF6679),
      onError: BTokens.bg,
      surface: BTokens.bg,
      onSurface: BTokens.ink,
      surfaceContainerHighest: BTokens.panel,
      outline: BTokens.goldDim,
    );

    final baseText = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: BTokens.bg,
      textTheme: baseText,
      appBarTheme: AppBarTheme(
        backgroundColor: BTokens.bg,
        foregroundColor: BTokens.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: BTokens.display(size: 20, italic: true),
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: BTokens.bgAlt,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: BTokens.ink20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BTokens.ink20,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BTokens.bg,
        indicatorColor: BTokens.bgAlt,
        labelTextStyle: WidgetStateProperty.all(
          BTokens.body(size: 10, color: BTokens.ink60),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: BTokens.gold);
          }
          return const IconThemeData(color: BTokens.ink40);
        }),
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: BTokens.bg,
        indicatorColor: BTokens.bgAlt,
        selectedIconTheme: const IconThemeData(color: BTokens.gold),
        unselectedIconTheme: const IconThemeData(color: BTokens.ink40),
        selectedLabelTextStyle: BTokens.body(size: 12, color: BTokens.gold),
        unselectedLabelTextStyle: BTokens.body(size: 12, color: BTokens.ink40),
      ),
    );
  }

  static ThemeData _buildCelestial(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      surface: brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
    );

    final baseText = GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: baseText,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black.withValues(alpha: 0.25),
        indicatorColor: Colors.white.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 10, color: Colors.white70),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: CTokens.gold);
          }
          return const IconThemeData(color: Colors.white60);
        }),
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.black.withValues(alpha: 0.25),
        indicatorColor: Colors.white.withValues(alpha: 0.15),
        selectedIconTheme: const IconThemeData(color: CTokens.gold),
        unselectedIconTheme: const IconThemeData(color: Colors.white60),
        selectedLabelTextStyle:
            GoogleFonts.inter(fontSize: 12, color: CTokens.gold),
        unselectedLabelTextStyle:
            GoogleFonts.inter(fontSize: 12, color: Colors.white60),
      ),
    );
  }
}
