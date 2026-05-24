import 'package:flutter/material.dart';

enum RegistrationFieldType { text, phone, password, dropdown, multiline }

class RegistrationFormConfig {
  final List<RegistrationFormFieldConfig> fields;

  const RegistrationFormConfig({required this.fields});

  factory RegistrationFormConfig.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final fields = rawFields is List
        ? rawFields
              .whereType<Map<String, dynamic>>()
              .map(RegistrationFormFieldConfig.fromJson)
              .where((field) => field.key.isNotEmpty)
              .toList()
        : defaultConfig.fields;

    return RegistrationFormConfig(
      fields: fields.isEmpty ? defaultConfig.fields : fields,
    );
  }

  Map<String, dynamic> toJson() {
    return {'fields': fields.map((field) => field.toJson()).toList()};
  }

  RegistrationFormConfig copyWith({List<RegistrationFormFieldConfig>? fields}) {
    return RegistrationFormConfig(fields: fields ?? this.fields);
  }

  static final defaultConfig = RegistrationFormConfig(
    fields: [
      RegistrationFormFieldConfig.core(
        key: 'fullName',
        label: 'الاسم بالكامل',
        type: RegistrationFieldType.text,
        iconName: 'person',
        required: true,
      ),
      RegistrationFormFieldConfig.core(
        key: 'phone',
        label: 'رقم الهاتف',
        type: RegistrationFieldType.phone,
        iconName: 'phone',
        required: true,
      ),
      RegistrationFormFieldConfig.core(
        key: 'password',
        label: 'كلمة المرور',
        type: RegistrationFieldType.password,
        iconName: 'lock',
        required: true,
      ),
      RegistrationFormFieldConfig.core(
        key: 'confirmPassword',
        label: 'تأكيد كلمة المرور',
        type: RegistrationFieldType.password,
        iconName: 'verified',
        required: true,
      ),
      RegistrationFormFieldConfig.core(
        key: 'address',
        label: 'المحافظة',
        type: RegistrationFieldType.dropdown,
        iconName: 'location',
        required: true,
        options: _egyptGovernorates,
      ),
      RegistrationFormFieldConfig.core(
        key: 'job',
        label: 'الوظيفة',
        type: RegistrationFieldType.dropdown,
        iconName: 'work',
        required: true,
        options: _jobs,
      ),
      RegistrationFormFieldConfig.core(
        key: 'language',
        label: 'اللغة المهتم بها',
        type: RegistrationFieldType.dropdown,
        iconName: 'translate',
        required: true,
        options: ['الإنجليزية', 'الألمانية'],
      ),
      RegistrationFormFieldConfig.core(
        key: 'learningReason',
        label: 'سبب تعلم اللغة',
        type: RegistrationFieldType.dropdown,
        iconName: 'flag',
        required: true,
        options: ['السفر', 'الدراسة', 'الشغل', 'تعليم الأولاد', 'سبب أخر'],
      ),
      RegistrationFormFieldConfig.core(
        key: 'referralReason',
        label: 'لماذا اخترتنا؟',
        type: RegistrationFieldType.text,
        iconName: 'favorite',
        required: true,
      ),
    ],
  );
}

class RegistrationFormFieldConfig {
  final String key;
  final String label;
  final RegistrationFieldType type;
  final bool required;
  final bool enabled;
  final bool isCore;
  final String iconName;
  final List<String> options;

  const RegistrationFormFieldConfig({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.enabled,
    required this.isCore,
    required this.iconName,
    required this.options,
  });

  const RegistrationFormFieldConfig.core({
    required this.key,
    required this.label,
    required this.type,
    required this.iconName,
    required this.required,
    this.options = const [],
  }) : enabled = true,
       isCore = true;

  factory RegistrationFormFieldConfig.fromJson(Map<String, dynamic> json) {
    final type = _typeFromString(json['type']?.toString());
    final options = json['options'] is List
        ? (json['options'] as List)
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];

    return RegistrationFormFieldConfig(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: type,
      required: json['required'] != false,
      enabled: json['enabled'] != false,
      isCore: json['isCore'] == true,
      iconName: json['icon']?.toString() ?? 'text',
      options: options,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type.name,
      'required': required,
      'enabled': enabled,
      'isCore': isCore,
      'icon': iconName,
      'options': options,
    };
  }

  RegistrationFormFieldConfig copyWith({
    String? key,
    String? label,
    RegistrationFieldType? type,
    bool? required,
    bool? enabled,
    bool? isCore,
    String? iconName,
    List<String>? options,
  }) {
    return RegistrationFormFieldConfig(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      enabled: enabled ?? this.enabled,
      isCore: isCore ?? this.isCore,
      iconName: iconName ?? this.iconName,
      options: options ?? this.options,
    );
  }

  bool get isDropdown => type == RegistrationFieldType.dropdown;

  IconData get icon {
    return switch (iconName) {
      'person' => Icons.person_rounded,
      'phone' => Icons.phone_rounded,
      'lock' => Icons.lock_rounded,
      'verified' => Icons.verified_user_rounded,
      'location' => Icons.location_on_rounded,
      'work' => Icons.work_rounded,
      'translate' => Icons.translate_rounded,
      'flag' => Icons.flag_rounded,
      'favorite' => Icons.favorite_rounded,
      'email' => Icons.email_rounded,
      'calendar' => Icons.calendar_month_rounded,
      _ => Icons.text_fields_rounded,
    };
  }

  static RegistrationFieldType _typeFromString(String? value) {
    return RegistrationFieldType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => RegistrationFieldType.text,
    );
  }
}

const _egyptGovernorates = [
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

const _jobs = [
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
