import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class BlogCategoryFormDialog extends StatefulWidget {
  final BlogCategory? initialData;
  final SnackbarService snackbarService;

  const BlogCategoryFormDialog({
    super.key,
    this.initialData,
    required this.snackbarService,
  });

  bool get isUpdate => initialData != null;

  @override
  State<BlogCategoryFormDialog> createState() => _BlogCategoryFormDialogState();
}

class _BlogCategoryFormDialogState extends State<BlogCategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _apiErrorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialData?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _apiErrorMessage = null);
    final blogVm = context.read<BlogVm>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    bool success;
    if (widget.isUpdate) {
      success = await blogVm.updateBlogCategory(
        widget.initialData!.id,
        name: name,
        description: description,
      );
    } else {
      success = await blogVm.createBlogCategory(
        name: name,
        description: description,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        widget.snackbarService.showSuccess(
          widget.isUpdate
              ? AppLocalizations.of(
                  context,
                ).translate('update_category_success')
              : AppLocalizations.of(
                  context,
                ).translate('create_category_success'),
        );
      } else {
        setState(() {
          _apiErrorMessage =
              blogVm.categoryError ??
              AppLocalizations.of(context).translate('failed');
          blogVm.clearCategoryError();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isLoading = context.watch<BlogVm>().isUpdatingEntity;

    return AlertDialog(
      backgroundColor: theme.popover,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.isUpdate
            ? AppLocalizations.of(context).translate('update_category_title')
            : AppLocalizations.of(context).translate('create_category_title'),
        style: TextStyle(
          color: theme.popoverForeground,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: theme.textColor),
                autofocus: true,
                decoration: _buildInputDecoration(
                  theme: theme,
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('category_name_label'),
                  hintText: AppLocalizations.of(
                    context,
                  ).translate('category_name_hint'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(
                      context,
                    ).translate('category_name_required');
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _apiErrorMessage = null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: theme.textColor),
                decoration: _buildInputDecoration(
                  theme: theme,
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('category_desc_label'),
                  hintText: AppLocalizations.of(
                    context,
                  ).translate('category_desc_hint'),
                ),
                maxLines: 3,
                minLines: 1,
                onChanged: (_) => setState(() => _apiErrorMessage = null),
              ),
              if (_apiErrorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _apiErrorMessage!,
                  style: TextStyle(color: theme.destructive, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context).translate('cancel'),
            style: TextStyle(color: theme.mutedForeground),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primary,
            foregroundColor: theme.primaryForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  widget.isUpdate
                      ? AppLocalizations.of(context).translate('save')
                      : AppLocalizations.of(context).translate('create'),
                ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required CustomThemeExtension theme,
    required String labelText,
    required String hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: theme.mutedForeground),
      hintText: hintText,
      hintStyle: TextStyle(color: theme.mutedForeground.withOpacity(0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: theme.primary, width: 1.5),
      ),
      filled: true,
      fillColor: theme.input,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      isDense: true,
    );
  }
}
