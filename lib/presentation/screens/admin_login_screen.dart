import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/services/admin_api_service.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/push_notification_service.dart';
import '../widgets/app_text_field.dart';
import 'admin_shell_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@lingova.com');
  final _passwordController = TextEditingController(text: 'admin123');
  final _service = AdminApiService();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final session = await _service.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await PushNotificationService.instance.bindAdmin(
        adminId: session.email.isNotEmpty ? session.email : 'system-admin',
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminShellScreen(session: session)),
      );
    } on AuthApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('تعذر الاتصال بلوحة التحكم.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.orangeSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.orange),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.orange,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'تسجيل دخول الأدمن',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'هذه الصفحة مخصصة لإدارة الطلاب والكورسات وليست لحسابات الطلاب.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: AppColors.textMuted, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _emailController,
                      label: 'البريد الإلكتروني أو رقم الهاتف',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _passwordController,
                      label: 'كلمة المرور',
                      icon: Icons.lock_rounded,
                      obscureText: true,
                      validator: _required,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _login,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login_rounded),
                      label: const Text('دخول لوحة التحكم'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
