import 'package:flutter/material.dart';

import 'core/app.dart';
import 'data/services/push_notification_service.dart';
import 'presentation/screens/admin_login_screen.dart';

export 'core/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.instance.prepareApp();
  runApp(const LingovaApp(home: AdminLoginScreen()));
}
