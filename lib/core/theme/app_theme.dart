import 'package:flutter/material.dart';

abstract class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF09090B),
    primaryColor: const Color(0xFFEAB308),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFEAB308),
      surface: Color(0xFF18181B),
      onSurface: Color(0xFFFAFAFA),
    ),
    fontFamily: 'PlusJakartaSans',
    useMaterial3: true,
  );
}
