import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kElectricBlue = Color(0xFF007BFF);

ThemeData buildDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.interTextTheme(base.textTheme);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: kElectricBlue,
      secondary: kElectricBlue,
      surface: const Color(0xFF121212),
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0E0E0F),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0E0E0F),
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      actionsIconTheme: const IconThemeData(color: Colors.white70),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF141414),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kElectricBlue, width: 1.3),
      ),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kElectricBlue,
      foregroundColor: Colors.white,
    ),
    dialogTheme: const DialogTheme(
      backgroundColor: Color(0xFF161616),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white70,
    ),
  );
}
