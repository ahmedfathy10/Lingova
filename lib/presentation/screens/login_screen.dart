import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/login_request.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/auth_storage_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_header.dart';
import 'main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authApiService = AuthApiService();

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authApiService.login(
        LoginRequest(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        ),
      );

      await AuthStorageService.saveUser(user);
      await _showSuccessDialog();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainScreen(user: user)),
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('تعذر الاتصال بالسيرفر. تأكد أن الباك اند يعمل.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.info_rounded, color: AppColors.orange, size: 38),
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('تنبيه', textAlign: TextAlign.center),
        ),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(message, textAlign: TextAlign.center),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.orange.withValues(alpha: .35),
                  ),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.orange,
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'تم تسجيل الدخول بنجاح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'جاهز نكمل رحلتك التعليمية.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.5),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('متابعة'),
                ),
              ),
            ],
          ),
        ),
      ),
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 28),
              const AuthHeader(
                title: 'مرحباً بعودتك',
                subtitle:
                    'سجّل دخولك برقم الهاتف وكلمة المرور لمتابعة رحلتك التعليمية.',
                centerContent: true,
                titleSubtitleSpacing: 16,
              ),
              const SizedBox(height: 34),
              AppTextField(
                controller: _phoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
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
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Text('تسجيل الدخول', textAlign: TextAlign.right),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'إنشاء حساب جديد',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'ليس لديك حساب؟',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
