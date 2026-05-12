import 'package:flutter_test/flutter_test.dart';

import 'package:lingova_app/core/app.dart';
import 'package:lingova_app/presentation/screens/admin_login_screen.dart';

void main() {
  testWidgets('App loads admin login smoke test', (tester) async {
    await tester.pumpWidget(const LingovaApp(home: AdminLoginScreen()));

    expect(find.text('تسجيل دخول الأدمن'), findsOneWidget);
    expect(find.text('دخول لوحة التحكم'), findsOneWidget);
  });
}
