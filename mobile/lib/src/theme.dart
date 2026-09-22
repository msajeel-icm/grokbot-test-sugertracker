import 'package:flutter/material.dart';

const sugarGreen = Color(0xFF1F6B4A);
const sugarInk = Color(0xFF1C1917);
const sugarPaper = Color(0xFFF4F0EA);
const sugarLine = Color(0xFFE4DCD2);

ThemeData buildSugarTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: sugarGreen,
    primary: sugarGreen,
    onPrimary: Colors.white,
    surface: sugarPaper,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: sugarLine),
  );
  final focused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: sugarGreen, width: 1.6),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: sugarPaper,
    appBarTheme: const AppBarTheme(
      backgroundColor: sugarPaper,
      foregroundColor: sugarInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: focused,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        foregroundColor: sugarInk,
      ),
    ),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: sugarInk,
      displayColor: sugarInk,
    ),
  );
}
