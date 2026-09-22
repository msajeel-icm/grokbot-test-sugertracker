import 'package:flutter/material.dart';

import '../format.dart';

/// Flat neutrals. Budget color is the only accent, and it does not glow.
class AppTokens {
  static const offWhite = Color(0xFFF7F7F5);
  static const nearBlack = Color(0xFF0A0A0A);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF141414);
  static const lightBorder = Color(0xFFE6E6E4);
  static const darkBorder = Color(0xFF2E2E2E);
  static const lightText = Color(0xFF171717);
  static const darkText = Color(0xFFF5F5F4);
  static const lightMuted = Color(0xFF737373);
  static const darkMuted = Color(0xFFA3A3A3);
  static const under = Color(0xFF0F766E);
  static const underDark = Color(0xFF2BBBAD);
  static const amber = Color(0xFFB45309);
  static const amberDark = Color(0xFFE0A14A);
  static const over = Color(0xFFB91C1C);
  static const overDark = Color(0xFFF07167);
}

class Space {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class Palette {
  Palette(this.brightness);

  final Brightness brightness;

  bool get dark => brightness == Brightness.dark;

  Color get background => dark ? AppTokens.nearBlack : AppTokens.offWhite;
  Color get surface => dark ? AppTokens.darkSurface : AppTokens.lightSurface;
  Color get border => dark ? AppTokens.darkBorder : AppTokens.lightBorder;
  Color get text => dark ? AppTokens.darkText : AppTokens.lightText;
  Color get muted => dark ? AppTokens.darkMuted : AppTokens.lightMuted;
  Color get under => dark ? AppTokens.underDark : AppTokens.under;
  Color get amber => dark ? AppTokens.amberDark : AppTokens.amber;
  Color get over => dark ? AppTokens.overDark : AppTokens.over;

  Color tone(BudgetTone tone) {
    switch (tone) {
      case BudgetTone.under:
        return under;
      case BudgetTone.atLimit:
        return amber;
      case BudgetTone.over:
        return over;
    }
  }

  static Palette of(BuildContext context) => Palette(Theme.of(context).brightness);
}
