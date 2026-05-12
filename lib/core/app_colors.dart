import 'package:flutter/material.dart';

import 'app_settings.dart';

class AppColors {
  static Color get background => AppSettings.isDarkMode
      ? const Color(0xFF0B0D12)
      : const Color(0xFFF6F7FB);

  static Color get surface =>
      AppSettings.isDarkMode ? const Color(0xFF151922) : Colors.white;

  static Color get surfaceHigh => AppSettings.isDarkMode
      ? const Color(0xFF1D2330)
      : const Color(0xFFEFF2F8);

  static const orange = Color(0xFFFF7A00);
  static const orangeSoft = Color(0x33FF7A00);

  static Color get border => AppSettings.isDarkMode
      ? const Color(0x1FFFFFFF)
      : const Color(0x140B0D12);

  static Color get textPrimary =>
      AppSettings.isDarkMode ? Colors.white : const Color(0xFF151922);

  static Color get textMuted => AppSettings.isDarkMode
      ? const Color(0xB3FFFFFF)
      : const Color(0xFF667085);
}
