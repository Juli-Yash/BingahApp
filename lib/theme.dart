// theme.dart
import 'package:flutter/material.dart';

const Color bingahPrimaryBlue = Color(0xFF1E88E5);
const Color bingahPrimaryGreen = Color(0xFF4CAF50); // Ini adalah hijau utama
const Color bingahLightBlue = Color(0xFF29B6F6);
const Color bingahLightGreen = Color(0xFF81C784);
const Color bingahTextDark = Color(0xFF000000);
const Color bingahTextGrey = Color(0xFF757575);
const Color bingahBackgroundLight = Color(0xFFF5F5F5);
const Color bingahWhite = Color(0xFFFFFFFF);

final ThemeData bingahTheme = ThemeData(
  primaryColor: bingahPrimaryGreen,
  colorScheme: ColorScheme.fromSeed(
    seedColor: bingahPrimaryGreen,
    primary: bingahPrimaryGreen,
    secondary: bingahPrimaryBlue,
    onPrimary: bingahWhite,
    onSecondary: bingahWhite,
    surface: bingahWhite,
    onSurface: bingahTextDark,
    background: bingahBackgroundLight,
    onBackground: bingahTextDark,
  ),
  scaffoldBackgroundColor: bingahBackgroundLight,
  appBarTheme: const AppBarTheme(
    color: bingahPrimaryGreen, // AppBar juga hijau
    foregroundColor: bingahWhite,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor:
          bingahPrimaryBlue, // Tombol utama (Ukur/Simpan) jadi biru
      foregroundColor: bingahWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: const EdgeInsets.symmetric(vertical: 15),
      textStyle: const TextStyle(fontSize: 18),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: const BorderSide(color: bingahTextGrey),
      foregroundColor: bingahTextDark,
      textStyle: const TextStyle(fontSize: 18),
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: bingahTextGrey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: bingahPrimaryGreen),
    ),
    labelStyle: TextStyle(color: bingahTextGrey),
    hintStyle: TextStyle(color: bingahTextGrey),
    prefixIconColor: bingahTextGrey,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: bingahTextDark),
    bodyMedium: TextStyle(color: bingahTextDark),
  ),
);
