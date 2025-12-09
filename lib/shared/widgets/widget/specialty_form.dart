import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'dart:io';
import '../common/image_display.dart';

import 'doctor_form.dart';

class SpecialtyForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final Future<bool> Function({
    required String name,
    String? description,
    String? iconUrl,
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
  String? _initialIconUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData?['name'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialData?['description'] ?? '',
    );
    _initialIconUrl = widget.initialData?['iconUrl'];

    // Reset VM upload state on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpecialtyVm>().resetIconState();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _submitForm() async {
    final vm = context.read<SpecialtyVm>();

    if (vm.isUploadingIcon) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Uploading icon, please wait..."),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    String? finalIconUrl = _initialIconUrl;
    if (vm.uploadedIconUrl != null) {
      finalIconUrl = vm.uploadedIconUrl;
    }

    if (_formKey.currentState!.validate()) {
      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        iconUrl: finalIconUrl,
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
            _buildIconPicker(context),
            const SizedBox(height: 20),
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

  Widget _buildIconPicker(BuildContext context) {
    final theme = context.theme;
    final vm = context.watch<SpecialtyVm>();

    File? selectedFile = vm.selectedIconFile;
    String? displayUrl = vm.uploadedIconUrl ?? _initialIconUrl;
    bool isUploading = vm.isUploadingIcon;

    Widget imageWidget;
    if (selectedFile != null) {
      imageWidget = Image.file(
        selectedFile,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else if (displayUrl != null && displayUrl.isNotEmpty) {
      imageWidget = CommonImage(
        imageUrl: displayUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Icon(
        Icons.add_a_photo,
        size: 40,
        color: theme.mutedForeground,
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: isUploading ? null : () => vm.pickIconImage(),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: theme.input,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                imageWidget,
                if (isUploading)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (vm.iconUploadError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              vm.iconUploadError!,
              style: TextStyle(color: theme.destructive, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).translate('specialty_icon_label') ??
              "Specialty Icon",
          style: TextStyle(color: theme.mutedForeground, fontSize: 12),
        ),
      ],
    );
  }
}
