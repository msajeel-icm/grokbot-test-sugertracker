import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildAppTheme(Brightness brightness) {
  final palette = Palette(brightness);
  final text = palette.text;
  final border = palette.border;
  final radius = BorderRadius.circular(18);
  const ink = Color(0xFF171917);

  OutlineInputBorder outline(Color color) {
    return OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: 1),
    );
  }

  TextStyle style(
    double size,
    FontWeight weight, {
    double height = 1.35,
    double tracking = 0,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: tracking,
      color: color ?? text,
    );
  }

  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF171717),
    brightness: brightness,
  ).copyWith(
    primary: text,
    onPrimary: palette.background,
    secondary: palette.muted,
    onSecondary: palette.surface,
    surface: palette.surface,
    onSurface: text,
    error: palette.over,
    onError: Colors.white,
    outline: border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Inter',
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    dividerColor: border,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: palette.border.withValues(alpha: 0.35),
    textTheme: TextTheme(
      headlineLarge: style(40, FontWeight.w800, height: 1.02, tracking: -1.4),
      headlineMedium: style(28, FontWeight.w800, height: 1.1, tracking: -0.7),
      titleLarge: style(20, FontWeight.w700, height: 1.2, tracking: -0.4),
      titleMedium: style(16, FontWeight.w700, tracking: -0.2),
      bodyLarge: style(16, FontWeight.w400),
      bodyMedium: style(14, FontWeight.w400),
      bodySmall: style(13, FontWeight.w400, color: palette.muted),
      labelLarge: style(14, FontWeight.w600, tracking: -0.1),
      labelSmall:
          style(12, FontWeight.w600, tracking: 0.3, color: palette.muted),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: palette.background,
      foregroundColor: text,
      centerTitle: false,
      titleTextStyle: style(18, FontWeight.w600, tracking: -0.3),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: AppTokens.lime,
        foregroundColor: ink,
        disabledBackgroundColor: AppTokens.lime.withValues(alpha: 0.45),
        disabledForegroundColor: ink.withValues(alpha: 0.45),
        minimumSize: const Size.fromHeight(54),
        shape: const StadiumBorder(),
        textStyle: style(16, FontWeight.w700, color: ink),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: palette.surface,
        foregroundColor: text,
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: border),
        shape: const StadiumBorder(),
        textStyle: style(16, FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.muted,
        textStyle: style(14, FontWeight.w600, color: palette.muted),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: style(15, FontWeight.w400, color: palette.muted),
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(text),
      errorBorder: outline(palette.over),
      focusedErrorBorder: outline(palette.over),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: text,
      selectionColor: border,
      selectionHandleColor: text,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.under),
    dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
  );
}
