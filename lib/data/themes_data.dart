import 'package:flutter/material.dart';

const _cairoFamily = 'Cairo';

TextTheme _cairoTextTheme(Color color) {
  return TextTheme(
    displayLarge: TextStyle(fontFamily: _cairoFamily, color: color),
    displayMedium: TextStyle(fontFamily: _cairoFamily, color: color),
    displaySmall: TextStyle(fontFamily: _cairoFamily, color: color),
    headlineLarge: TextStyle(fontFamily: _cairoFamily, color: color),
    headlineMedium: TextStyle(fontFamily: _cairoFamily, color: color),
    headlineSmall: TextStyle(fontFamily: _cairoFamily, color: color),
    titleLarge: TextStyle(fontFamily: _cairoFamily, color: color),
    titleMedium: TextStyle(fontFamily: _cairoFamily, color: color),
    titleSmall: TextStyle(fontFamily: _cairoFamily, color: color),
    bodyLarge: TextStyle(fontFamily: _cairoFamily, color: color),
    bodyMedium: TextStyle(fontFamily: _cairoFamily, color: color),
    bodySmall: TextStyle(fontFamily: _cairoFamily, color: color),
    labelLarge: TextStyle(fontFamily: _cairoFamily, color: color),
    labelMedium: TextStyle(fontFamily: _cairoFamily, color: color),
    labelSmall: TextStyle(fontFamily: _cairoFamily, color: color),
  );
}

ThemeData lightModeTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xfff8f8f8),
  primaryColor: Colors.black,
  fontFamily: _cairoFamily,
  colorScheme: ColorScheme.light(
    primary: Colors.black,
    secondary: const Color(0xff12ce31),
  ),
  textTheme: _cairoTextTheme(Colors.black),
  cardColor: Colors.white,
);

ThemeData darkModeTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xff06090d),
  primaryColor: Colors.white,
  fontFamily: _cairoFamily,
  colorScheme: ColorScheme.dark(
    primary: Colors.white,
    secondary: Colors.white,
  ),
  textTheme: _cairoTextTheme(Colors.white),
  cardColor: const Color(0xff070606),
);
