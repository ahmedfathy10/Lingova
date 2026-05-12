import 'dart:ui';

import 'package:flutter/material.dart';

import '../presentation/screens/login_screen.dart';
import 'app_settings.dart';
import 'app_theme.dart';

class LingovaApp extends StatelessWidget {
  final Widget home;

  const LingovaApp({super.key, this.home = const LoginScreen()});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettings.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Lingova',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
          home: home,
        );
      },
    );
  }
}
