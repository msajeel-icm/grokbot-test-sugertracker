import 'package:flutter/material.dart';

import '../format.dart';

/// Soft mint page. [offWhite] and [nearBlack] keep their names because
/// widget tests compare the scaffold color to these tokens.
class AppTokens {
  static const offWhite = Color(0xFFE5F6E1);
  static const nearBlack = Color(0xFF101612);
  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF1A2420);
  static const lightBorder = Color(0xFFD7E8D4);
  static const darkBorder = Color(0xFF2C3A32);
  static const lightText = Color(0xFF171917);
  static const darkText = Color(0xFFF4F7F2);
  static const lightMuted = Color(0xFF7E877F);
  static const darkMuted = Color(0xFFA8B2AA);
  static const lime = Color(0xFF6BF24A);
  static const under = Color(0xFF3CBF45);
  static const underDark = Color(0xFF6BF24A);
  static const amber = Color(0xFFFF6E2E);
  static const amberDark = Color(0xFFFF8A4A);
  static const over = Color(0xFFE24B3B);
  static const overDark = Color(0xFFFF7A6E);
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
  Color get lime => AppTokens.lime;

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

  static Palette of(BuildContext context) =>
      Palette(Theme.of(context).brightness);
}
