import 'package:flutter/material.dart';

const kBrandRed = Color(0xFFA22A2A);
const kBrandGray = Color(0xFF5B5B5D);

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kBrandRed, brightness: Brightness.light);
  return ThemeData(colorScheme: scheme, useMaterial3: true);
}
