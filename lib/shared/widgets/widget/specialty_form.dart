import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import 'doctor_form.dart';

class SpecialtyForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final Future<bool> Function({
  required String name,
  String? description,
  String? id,
  }) onSubmit;
  final VoidCallback? onSuccess;

  const SpecialtyForm({
    super.key,
    required this.isUpdate,
    this.initialData,
    required this.onSubmit,
    this.onSuccess,
  });

  @override
  State<SpecialtyForm> createState() => _SpecialtyFormState();
}

class _SpecialtyFormState extends State<SpecialtyForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialData?['name'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialData?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );
      if (success) {
        widget.onSuccess?.call();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
      return success;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên chuyên khoa',
                prefixIcon:
                Icon(Icons.medical_services, color: context.theme.primary),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên chuyên khoa';
                }
                if (value.length < 10 || value.length > 200) {
                  return 'Tên phải từ 10 đến 200 ký tự';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                prefixIcon:
                Icon(Icons.description, color: context.theme.primary),
              ),
              maxLines: 5,
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    (value.length < 10 || value.length > 1000)) {
                  return 'Mô tả phải từ 10 đến 1000 ký tự nếu có';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            AnimatedSubmitButton(
              onSubmit: _submitForm,
              idleText:
              '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} chuyên khoa',
              loadingText: 'Đang xử lý...',
            ),
          ],
        ),
      ),
    );
  }
}