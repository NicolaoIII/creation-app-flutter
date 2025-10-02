import 'package:flutter/material.dart';

const kBrandRed  = Color(0xFFA22A2A);
const kBrandGray = Color(0xFF5B5B5D);
const kBrandWhite = Color(0xFFFFFFFF);

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kBrandRed,
    brightness: Brightness.light,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: kBrandWhite,
      foregroundColor: kBrandGray,
      elevation: 0.5,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 44),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 44),
        shape: const StadiumBorder(),
      ),
    ),
  );
}
