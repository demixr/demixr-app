import 'package:flutter/material.dart';

class ColorPalette {
  static const Color primary = Color.fromRGBO(255, 181, 157, 1);
  static const Color onPrimary = Color.fromRGBO(93, 23, 1, 1);
  static const Color surface = Color.fromRGBO(33, 26, 24, 1);
  static const Color onSurface = Color.fromRGBO(237, 224, 221, 1);
  static const Color surfaceVariant = Color.fromRGBO(83, 67, 63, 1);
  static const Color onSurfaceVariant = Color.fromRGBO(216, 194, 188, 1);
  static const Color tertiary = Color.fromRGBO(245, 226, 167, 1);
  static const Color onTertiary = Color.fromRGBO(58, 47, 4, 1);
  static const Color errorContainer = Color.fromRGBO(147, 0, 6, 1);
  static const Color onError = Color.fromRGBO(255, 218, 212, 1);
  static const Color inverseSurface = Color.fromRGBO(237, 224, 221, 1);
  static const Color inversePrimary = Color.fromRGBO(155, 68, 41, 1);
  static const List<Color> primaryGradient = [
    Color.fromRGBO(250, 184, 196, 1),
    Color.fromRGBO(89, 86, 233, 1),
  ];
  static const List<Color> primaryFadedGradient = [
    Color.fromRGBO(250, 184, 196, 0.25),
    Color.fromRGBO(89, 86, 233, 0.25),
  ];
}

class Paths {
  static const String images = 'assets/images/';
  static const String icons = 'assets/icons/';
}
