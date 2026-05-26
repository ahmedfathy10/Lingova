import 'package:flutter/material.dart';

import 'core/app.dart';
import 'data/models/auth_user.dart';
import 'data/services/auth_storage_service.dart';
import 'data/services/push_notification_service.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_screen.dart';

export 'core/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.instance.prepareApp();

  final AuthUser? savedUser = await AuthStorageService.loadUser();
  runApp(
    LingovaApp(
      home: savedUser != null
          ? MainScreen(user: savedUser)
          : const LoginScreen(),
    ),
  );
}
