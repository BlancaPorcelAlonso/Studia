import 'package:flutter/material.dart';

class CottagecoreColors {
  static const cream = Color(0xFFFBF7F0);
  static const creamDarker = Color(0xFFF3ECE1);
  static const creamCard = Color(0xFFFFFFFF);
  static const border = Color(0xFFE8DFD3);

  // Natural Accents
  static const sage = Color(0xFF729A7B);
  static const forest = Color(0xFF3B563F);
  static const warmBrown = Color(0xFF684E3C);
  static const terracotta = Color(0xFFC77A5C);
  static const dustyRose = Color(0xFFD49A9C);
  static const softGold = Color(0xFFD8B25A);

  // Status Colors
  static const urgentRed = Color(0xFFBA4B3B);
  static const urgentRedBg = Color(0xFFFBEBE8);
  static const warningOrange = Color(0xFFCE7538);
  static const warningOrangeBg = Color(0xFFFDF1E6);
  static const calmGreen = Color(0xFF568060);
  static const calmGreenBg = Color(0xFFEBF4EC);
}

class CottagecoreTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: CottagecoreColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: CottagecoreColors.sage,
        brightness: Brightness.light,
        primary: CottagecoreColors.sage,
        secondary: CottagecoreColors.forest,
        surface: CottagecoreColors.creamCard,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: CottagecoreColors.cream,
        foregroundColor: CottagecoreColors.forest,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: CottagecoreColors.forest,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'serif',
        ),
      ),
      cardTheme: CardThemeData(
        color: CottagecoreColors.creamCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: CottagecoreColors.border, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: CottagecoreColors.creamCard,
        elevation: 2,
        indicatorColor: CottagecoreColors.sage.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: CottagecoreColors.forest,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6E7A6F),
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: CottagecoreColors.forest,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CottagecoreColors.creamDarker,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CottagecoreColors.border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: CottagecoreColors.sage, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF7A6F62)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: CottagecoreColors.creamDarker,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CottagecoreColors.warmBrown,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: CottagecoreColors.border,
        thickness: 1,
        space: 24,
      ),
    );
  }
}
