import 'package:flutter/material.dart';

class AppSettings {
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  static bool get isDarkMode => themeMode.value != ThemeMode.light;

  static void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }
}
