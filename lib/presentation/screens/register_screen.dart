import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/register_request.dart';
import '../../data/models/registration_form_config.dart';
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
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String?> _dropdownValues = {};

  late Future<RegistrationFormConfig> _configFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _configFuture = _loadConfig();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<RegistrationFormConfig> _loadConfig() async {
    try {
      final config = await _authApiService.getRegistrationFormConfig();
      _syncFormState(config);
      return config;
    } catch (_) {
      final config = RegistrationFormConfig.defaultConfig;
      _syncFormState(config);
      return config;
    }
  }

  void _syncFormState(RegistrationFormConfig config) {
    for (final field in config.fields.where((field) => field.enabled)) {
      if (field.isDropdown) {
        _dropdownValues.putIfAbsent(
          field.key,
          () => field.options.isNotEmpty ? field.options.first : null,
        );
      } else {
        _controllers.putIfAbsent(field.key, TextEditingController.new);
      }
    }
  }

  Future<void> _register(RegistrationFormConfig config) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final values = <String, dynamic>{};
    for (final field in config.fields.where((field) => field.enabled)) {
      if (field.key == 'confirmPassword') {
        continue;
      }
      values[field.key] = field.isDropdown
          ? (_dropdownValues[field.key] ?? '')
          : (_controllers[field.key]?.text.trim() ?? '');
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authApiService.register(RegisterRequest(values));

      await AuthStorageService.saveUser(user);

      if (!mounted) return;

      await _showSuccessDialog();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainScreen(user: user)),
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
        icon: const Text('🎉', style: TextStyle(fontSize: 42)),
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
            child: const Text('يلا نبدأ'),
          ),
        ],
      ),
    );
  }

  String? _validateField(
    RegistrationFormFieldConfig field,
    String? value,
    RegistrationFormConfig config,
  ) {
    if (field.required && (value == null || value.trim().isEmpty)) {
      return 'هذا الحقل مطلوب';
    }

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (field.type == RegistrationFieldType.phone &&
        !RegExp(r'^[0-9+\-\s]{8,20}$').hasMatch(value.trim())) {
      return 'اكتب رقم هاتف صحيح';
    }

    if (field.key == 'password' && value.length < 6) {
      return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
    }

    if (field.key == 'confirmPassword') {
      final password = _controllers['password']?.text ?? '';
      if (value != password) {
        return 'كلمتا المرور غير متطابقتين';
      }
    }

    return null;
  }

  Widget _buildField(
    RegistrationFormFieldConfig field,
    RegistrationFormConfig config,
  ) {
    if (field.isDropdown) {
      return DropdownButtonFormField<String>(
        alignment: AlignmentDirectional.centerEnd,
        initialValue: _dropdownValues[field.key],
        isExpanded: true,
        items: field.options
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
        onChanged: _isLoading
            ? null
            : (value) => setState(() => _dropdownValues[field.key] = value),
        validator: (value) => _validateField(field, value, config),
        decoration: InputDecoration(
          labelText: field.label,
          prefixIcon: Icon(field.icon),
        ),
      );
    }

    return AppTextField(
      controller: _controllers[field.key],
      label: field.label,
      icon: field.icon,
      maxLines: field.type == RegistrationFieldType.multiline ? 3 : 1,
      keyboardType: field.type == RegistrationFieldType.phone
          ? TextInputType.phone
          : TextInputType.text,
      obscureText: field.type == RegistrationFieldType.password,
      validator: (value) => _validateField(field, value, config),
      textInputAction: TextInputAction.next,
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
        child: FutureBuilder<RegistrationFormConfig>(
          future: _configFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final config =
                snapshot.data ?? RegistrationFormConfig.defaultConfig;
            final fields = config.fields
                .where((field) => field.enabled)
                .toList();

            return Form(
              key: _formKey,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: fields.length + 4,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const AuthHeader(
                      title: 'ابدأ رحلتك معنا',
                      subtitle:
                          'املأ بياناتك مرة واحدة لنصمم لك تجربة تعلم مناسبة لهدفك.',
                      centerBrand: true,
                    );
                  }
                  if (index == 1) {
                    return const SizedBox(height: 14);
                  }
                  final fieldIndex = index - 2;
                  if (fieldIndex < fields.length) {
                    return _buildField(fields[fieldIndex], config);
                  }
                  if (fieldIndex == fields.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _register(config),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text(
                                'إنشاء الحساب',
                                textAlign: TextAlign.right,
                              ),
                      ),
                    );
                  }
                  return TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'لديك حساب بالفعل؟ تسجيل الدخول',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
