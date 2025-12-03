import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

import 'doctor_form.dart';

class SpecialtyForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final Future<bool> Function({
    required String name,
    String? description,
    String? id,
  })
  onSubmit;
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
    _nameController = TextEditingController(
      text: widget.initialData?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialData?['description'] ?? '',
    );
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
                labelText: AppLocalizations.of(
                  context,
                ).translate('specialty_name_label'),
                prefixIcon: Icon(
                  Icons.medical_services,
                  color: context.theme.primary,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(
                    context,
                  ).translate('specialty_name_required');
                }
                if (value.length < 10 || value.length > 200) {
                  return AppLocalizations.of(
                    context,
                  ).translate('specialty_name_length_error');
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).translate('specialty_desc_label'),
                prefixIcon: Icon(
                  Icons.description,
                  color: context.theme.primary,
                ),
              ),
              maxLines: 5,
              validator: (value) {
                if (value != null &&
                    value.isNotEmpty &&
                    (value.length < 10 || value.length > 1000)) {
                  return AppLocalizations.of(
                    context,
                  ).translate('specialty_desc_length_error');
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            AnimatedSubmitButton(
              onSubmit: _submitForm,
              idleText: widget.isUpdate
                  ? '${AppLocalizations.of(context).translate('update_btn')} ${AppLocalizations.of(context).translate('specialty_label')}'
                  : '${AppLocalizations.of(context).translate('create_btn')} ${AppLocalizations.of(context).translate('specialty_label')}',
              loadingText: AppLocalizations.of(context).translate('processing'),
            ),
          ],
        ),
      ),
    );
  }
}
