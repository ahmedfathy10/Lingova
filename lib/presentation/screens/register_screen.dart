import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/register_request.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/auth_storage_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_header.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authApiService = AuthApiService();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralReasonController = TextEditingController();

  String language = 'الإنجليزية';
  String? city;
  String? job;
  String? learningReason;
  bool _isLoading = false;

  static const _egyptGovernorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'البحر الأحمر',
    'البحيرة',
    'الفيوم',
    'الغربية',
    'الإسماعيلية',
    'المنوفية',
    'المنيا',
    'القليوبية',
    'الوادي الجديد',
    'السويس',
    'أسوان',
    'أسيوط',
    'بني سويف',
    'بورسعيد',
    'دمياط',
    'الشرقية',
    'جنوب سيناء',
    'كفر الشيخ',
    'مطروح',
    'الأقصر',
    'قنا',
    'شمال سيناء',
    'سوهاج',
  ];

  static const _jobs = [
    'طالب',
    'معلم',
    'طبيب',
    'صيدلي',
    'مهندس',
    'محاسب',
    'محامي',
    'مصمم جرافيك',
    'مبرمج',
    'مصمم واجهات',
    'مسوق رقمي',
    'مندوب مبيعات',
    'خدمة عملاء',
    'موظف إداري',
    'مدير مشروع',
    'مدير موارد بشرية',
    'صاحب عمل',
    'رائد أعمال',
    'مترجم',
    'كاتب محتوى',
    'صحفي',
    'باحث',
    'عامل حر',
    'فني',
    'سائق',
    'ممرض',
    'مدرب',
    'مصمم أزياء',
    'ربة منزل',
    'أخرى',
  ];

  static const _languages = ['الإنجليزية', 'الألمانية'];

  static const _learningReasons = [
    'السفر',
    'الدراسة',
    'الشغل',
    'تعليم الأولاد',
    'سبب أخر',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralReasonController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authApiService.register(
        RegisterRequest(
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          address: city ?? '',
          job: job ?? '',
          language: language,
          learningReason: learningReason ?? '',
          referralReason: _referralReasonController.text.trim(),
        ),
      );

      await AuthStorageService.saveUser(user);

      if (!mounted) return;

      await _showSuccessDialog();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainScreen(user: user),
        ),
        (_) => false,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(message, textAlign: TextAlign.right),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Text('🎉', style: TextStyle(fontSize: 42)),
        title: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text('تم تسجيل الحساب بنجاح', textAlign: TextAlign.center),
        ),
        content: const Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'رحلتك لتعلم اللغات هتبدأ دلوقتي ✨',
            textAlign: TextAlign.center,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('يلا نبدأ'),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;

    final phone = value!.trim();
    if (!RegExp(r'^[0-9+\-\s]{8,20}$').hasMatch(phone)) {
      return 'اكتب رقم هاتف صحيح';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;

    if (value!.length < 6) {
      return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;

    if (value != _passwordController.text) {
      return 'كلمتا المرور غير متطابقتين';
    }

    return null;
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      alignment: AlignmentDirectional.centerEnd,
      initialValue: value,
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  item,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: _isLoading ? null : onChanged,
      validator: _required,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const AuthHeader(
                title: 'ابدأ رحلتك معنا',
                subtitle:
                    'املأ بياناتك مرة واحدة لنصمم لك تجربة تعلم مناسبة لهدفك.',
                centerBrand: true,
              ),
              SizedBox(height: 28),
              AppTextField(
                controller: _fullNameController,
                label: 'الاسم بالكامل',
                icon: Icons.person_rounded,
                validator: _required,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 14),
              AppTextField(
                controller: _phoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 14),
              AppTextField(
                controller: _passwordController,
                label: 'كلمة المرور',
                icon: Icons.lock_rounded,
                obscureText: true,
                validator: _validatePassword,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 14),
              AppTextField(
                controller: _confirmPasswordController,
                label: 'تأكيد كلمة المرور',
                icon: Icons.verified_user_rounded,
                obscureText: true,
                validator: _validateConfirmPassword,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 14),
              _buildDropdownField(
                value: city,
                items: _egyptGovernorates,
                onChanged: (value) => setState(() => city = value),
                label: 'المحافظة',
                icon: Icons.location_on_rounded,
              ),
              SizedBox(height: 14),
              _buildDropdownField(
                value: job,
                items: _jobs,
                onChanged: (value) => setState(() => job = value),
                label: 'الوظيفة',
                icon: Icons.work_rounded,
              ),
              SizedBox(height: 14),
              _buildDropdownField(
                value: language,
                items: _languages,
                onChanged: (value) => setState(() {
                  language = value ?? language;
                }),
                label: 'اللغة المهتم بها',
                icon: Icons.translate_rounded,
              ),
              SizedBox(height: 14),
              _buildDropdownField(
                value: learningReason,
                items: _learningReasons,
                onChanged: (value) => setState(() => learningReason = value),
                label: 'سبب تعلم اللغة',
                icon: Icons.flag_rounded,
              ),
              SizedBox(height: 14),
              AppTextField(
                controller: _referralReasonController,
                label: 'لماذا اخترتنا؟',
                icon: Icons.favorite_rounded,
                validator: _required,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : Text('إنشاء الحساب', textAlign: TextAlign.right),
              ),
              SizedBox(height: 14),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(
                  'لديك حساب بالفعل؟ تسجيل الدخول',
                  textAlign: TextAlign.right,
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
