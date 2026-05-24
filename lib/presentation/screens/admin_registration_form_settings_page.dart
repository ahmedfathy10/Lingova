import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../data/models/registration_form_config.dart';
import '../../data/services/admin_api_service.dart';
import '../../data/services/auth_api_service.dart';

class AdminRegistrationFormSettingsPage extends StatefulWidget {
  final AdminSession session;

  const AdminRegistrationFormSettingsPage({super.key, required this.session});

  @override
  State<AdminRegistrationFormSettingsPage> createState() =>
      _AdminRegistrationFormSettingsPageState();
}

class _AdminRegistrationFormSettingsPageState
    extends State<AdminRegistrationFormSettingsPage> {
  final _service = AdminApiService();
  late Future<RegistrationFormConfig> _future;
  RegistrationFormConfig? _config;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<RegistrationFormConfig> _load() async {
    final config = await _service.getRegistrationFormConfig(
      widget.session.token,
    );
    _config = config;
    return config;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.right)),
    );
  }

  Future<void> _save() async {
    final config = _config;
    if (config == null) return;

    setState(() => _saving = true);
    try {
      await _service.updateRegistrationFormConfig(widget.session.token, config);
      _showMessage('تم حفظ إعدادات فورم التسجيل.');
    } on AuthApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('تعذر حفظ إعدادات فورم التسجيل.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _editField(int index) async {
    final config = _config;
    if (config == null) return;

    final result = await showDialog<RegistrationFormFieldConfig>(
      context: context,
      builder: (_) => _RegistrationFieldDialog(field: config.fields[index]),
    );
    if (result == null) return;

    final fields = [...config.fields];
    fields[index] = result;
    setState(() => _config = config.copyWith(fields: fields));
  }

  Future<void> _addField() async {
    final config = _config;
    if (config == null) return;

    final result = await showDialog<RegistrationFormFieldConfig>(
      context: context,
      builder: (_) => const _RegistrationFieldDialog(),
    );
    if (result == null) return;

    final existingKeys = config.fields.map((field) => field.key).toSet();
    var field = result;
    var key = field.key;
    var index = 2;
    while (existingKeys.contains(key)) {
      key = '${field.key}_$index';
      index++;
    }
    field = field.copyWith(key: key);

    setState(
      () => _config = config.copyWith(fields: [...config.fields, field]),
    );
  }

  void _removeField(int index) {
    final config = _config;
    if (config == null) return;
    final field = config.fields[index];
    if (field.isCore) {
      _showMessage('لا يمكن حذف الحقول الأساسية، يمكنك إخفاء بعضها فقط.');
      return;
    }
    final fields = [...config.fields]..removeAt(index);
    setState(() => _config = config.copyWith(fields: fields));
  }

  void _moveField(int index, int direction) {
    final config = _config;
    if (config == null) return;
    final nextIndex = index + direction;
    if (nextIndex < 0 || nextIndex >= config.fields.length) return;
    final fields = [...config.fields];
    final field = fields.removeAt(index);
    fields.insert(nextIndex, field);
    setState(() => _config = config.copyWith(fields: fields));
  }

  void _resetDefaults() {
    setState(() => _config = RegistrationFormConfig.defaultConfig);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<RegistrationFormConfig>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _config == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && _config == null) {
            return Center(
              child: Text(
                'تعذر تحميل إعدادات فورم التسجيل.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          final config = _config ?? RegistrationFormConfig.defaultConfig;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            children: [
              _SettingsHeader(
                saving: _saving,
                onAdd: _addField,
                onReset: _resetDefaults,
                onSave: _save,
              ),
              const SizedBox(height: 18),
              ...List.generate(config.fields.length, (index) {
                final field = config.fields[index];
                return _FieldCard(
                  field: field,
                  onEdit: () => _editField(index),
                  onDelete: () => _removeField(index),
                  onMoveUp: index == 0 ? null : () => _moveField(index, -1),
                  onMoveDown: index == config.fields.length - 1
                      ? null
                      : () => _moveField(index, 1),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  final bool saving;
  final VoidCallback onAdd;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const _SettingsHeader({
    required this.saving,
    required this.onAdd,
    required this.onReset,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'إعدادات فورم تسجيل العملاء',
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          'غيّر أسماء الحقول، الإلزام، الظهور، والاختيارات. يمكنك إضافة حقول مخصصة تظهر مباشرة في صفحة التسجيل.',
          textAlign: TextAlign.right,
          style: TextStyle(color: AppColors.textMuted, height: 1.4),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: saving ? null : onSave,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('حفظ'),
            ),
            OutlinedButton.icon(
              onPressed: saving ? null : onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة حقل'),
            ),
            TextButton.icon(
              onPressed: saving ? null : onReset,
              icon: const Icon(Icons.restore_rounded),
              label: const Text('استرجاع الافتراضي'),
            ),
          ],
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  final RegistrationFormFieldConfig field;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const _FieldCard({
    required this.field,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(field.icon),
        title: Text(
          field.label,
          textAlign: TextAlign.right,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            field.key,
            field.type.name,
            field.required ? 'مطلوب' : 'اختياري',
            field.enabled ? 'ظاهر' : 'مخفي',
            if (field.options.isNotEmpty) '${field.options.length} اختيار',
          ].join(' • '),
          textAlign: TextAlign.right,
        ),
        trailing: Wrap(
          spacing: 2,
          children: [
            IconButton(
              tooltip: 'أعلى',
              onPressed: onMoveUp,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            IconButton(
              tooltip: 'أسفل',
              onPressed: onMoveDown,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            IconButton(
              tooltip: 'تعديل',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              tooltip: 'حذف',
              onPressed: field.isCore ? null : onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegistrationFieldDialog extends StatefulWidget {
  final RegistrationFormFieldConfig? field;

  const _RegistrationFieldDialog({this.field});

  @override
  State<_RegistrationFieldDialog> createState() =>
      _RegistrationFieldDialogState();
}

class _RegistrationFieldDialogState extends State<_RegistrationFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _keyController;
  late final TextEditingController _labelController;
  late final TextEditingController _optionsController;
  late RegistrationFieldType _type;
  late bool _required;
  late bool _enabled;
  late String _iconName;

  bool get _isCore => widget.field?.isCore == true;

  @override
  void initState() {
    super.initState();
    final field = widget.field;
    _keyController = TextEditingController(text: field?.key ?? '');
    _labelController = TextEditingController(text: field?.label ?? '');
    _optionsController = TextEditingController(
      text: field?.options.join('\n') ?? '',
    );
    _type = field?.type ?? RegistrationFieldType.text;
    _required = field?.required ?? true;
    _enabled = field?.enabled ?? true;
    _iconName = field?.iconName ?? 'text';
  }

  @override
  void dispose() {
    _keyController.dispose();
    _labelController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final key = _isCore
        ? widget.field!.key
        : _keyController.text.trim().replaceAll(RegExp(r'\s+'), '_');
    final options = _optionsController.text
        .split(RegExp(r'\r?\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    Navigator.of(context).pop(
      RegistrationFormFieldConfig(
        key: key,
        label: _labelController.text.trim(),
        type: _type,
        required: _required,
        enabled: _enabled,
        isCore: _isCore,
        iconName: _iconName,
        options: _type == RegistrationFieldType.dropdown ? options : const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.field == null ? 'إضافة حقل' : 'تعديل حقل'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _keyController,
                  readOnly: _isCore,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'كود الحقل',
                    helperText:
                        'إنجليزي بدون مسافات مثل: age أو education_level',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'مطلوب';
                    }
                    if (!RegExp(
                      r'^[A-Za-z][A-Za-z0-9_]*$',
                    ).hasMatch(value.trim())) {
                      return 'استخدم حروف إنجليزية وأرقام و _ فقط';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _labelController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'اسم الحقل'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RegistrationFieldType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'نوع الحقل'),
                  items: const [
                    DropdownMenuItem(
                      value: RegistrationFieldType.text,
                      child: Text('نص قصير'),
                    ),
                    DropdownMenuItem(
                      value: RegistrationFieldType.multiline,
                      child: Text('نص طويل'),
                    ),
                    DropdownMenuItem(
                      value: RegistrationFieldType.phone,
                      child: Text('رقم هاتف'),
                    ),
                    DropdownMenuItem(
                      value: RegistrationFieldType.dropdown,
                      child: Text('اختيارات'),
                    ),
                  ],
                  onChanged: _isCore
                      ? null
                      : (value) {
                          if (value != null) setState(() => _type = value);
                        },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _iconName,
                  decoration: const InputDecoration(labelText: 'الأيقونة'),
                  items: const [
                    DropdownMenuItem(value: 'text', child: Text('نص')),
                    DropdownMenuItem(value: 'person', child: Text('شخص')),
                    DropdownMenuItem(value: 'phone', child: Text('هاتف')),
                    DropdownMenuItem(value: 'email', child: Text('إيميل')),
                    DropdownMenuItem(value: 'calendar', child: Text('تاريخ')),
                    DropdownMenuItem(value: 'location', child: Text('مكان')),
                    DropdownMenuItem(value: 'work', child: Text('عمل')),
                    DropdownMenuItem(value: 'translate', child: Text('لغة')),
                    DropdownMenuItem(value: 'flag', child: Text('هدف')),
                    DropdownMenuItem(value: 'favorite', child: Text('قلب')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _iconName = value);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _required,
                  onChanged:
                      _isCore &&
                          [
                            'fullName',
                            'phone',
                            'password',
                          ].contains(widget.field?.key)
                      ? null
                      : (value) => setState(() => _required = value),
                  title: const Text('الحقل مطلوب'),
                ),
                SwitchListTile(
                  value: _enabled,
                  onChanged:
                      _isCore &&
                          [
                            'fullName',
                            'phone',
                            'password',
                          ].contains(widget.field?.key)
                      ? null
                      : (value) => setState(() => _enabled = value),
                  title: const Text('إظهار الحقل في التسجيل'),
                ),
                if (_type == RegistrationFieldType.dropdown) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _optionsController,
                    minLines: 4,
                    maxLines: 8,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'الاختيارات',
                      helperText: 'اكتب كل اختيار في سطر منفصل',
                    ),
                    validator: (value) {
                      if (_type != RegistrationFieldType.dropdown) return null;
                      final count = (value ?? '')
                          .split(RegExp(r'\r?\n'))
                          .where((item) => item.trim().isNotEmpty)
                          .length;
                      return count == 0 ? 'أضف اختيار واحد على الأقل' : null;
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}
