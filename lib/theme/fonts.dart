import 'package:flutter/material.dart';

/// S-Core Dream Font Utility Helper
/// Configures S-Core Dream font family with graceful typography styling.
class AppFonts {
  static const String fontFamily = 'sCore Dream';

  static TextStyle sCoreDream({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }
}
