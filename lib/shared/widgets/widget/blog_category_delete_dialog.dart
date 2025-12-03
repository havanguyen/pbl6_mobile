import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class BlogCategoryDeleteDialog extends StatefulWidget {
  final BlogCategory category;
  final SnackbarService snackbarService;

  const BlogCategoryDeleteDialog({
    super.key,
    required this.category,
    required this.snackbarService,
  });

  @override
  State<BlogCategoryDeleteDialog> createState() =>
      _BlogCategoryDeleteDialogState();
}

class _BlogCategoryDeleteDialogState extends State<BlogCategoryDeleteDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _forceDelete = false;
  String? _apiErrorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(bool isLoading) async {
    if (isLoading) return;

    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _apiErrorMessage = AppLocalizations.of(
          context,
        ).translate('password_required');
      });
      return;
    }

    setState(() {
      _apiErrorMessage = null;
    });

    final provider = context.read<BlogVm>();
    final success = await provider.deleteBlogCategory(
      widget.category.id,
      password: password,
      forceBulkDelete: _forceDelete,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        widget.snackbarService.showSuccess(
          AppLocalizations.of(context).translate('delete_category_success'),
        );
      } else {
        setState(() {
          _apiErrorMessage =
              provider.categoryError ??
              AppLocalizations.of(context).translate('delete_failed');
          provider.clearCategoryError();
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
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.destructive),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).translate('confirm_delete_title'),
            style: TextStyle(
              color: theme.popoverForeground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(
                context,
              ).translate('confirm_delete_category_message'),
              style: TextStyle(
                color: theme.popoverForeground.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"${widget.category.name}"?',
              style: TextStyle(
                color: theme.popoverForeground,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: TextStyle(color: theme.textColor),
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).translate('enter_password_confirm'),
                labelStyle: TextStyle(color: theme.mutedForeground),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                isDense: true,
              ),
              onChanged: (_) {
                if (_apiErrorMessage != null) {
                  setState(() => _apiErrorMessage = null);
                }
              },
              onSubmitted: (_) => _confirmDelete(isLoading),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: Text(
                AppLocalizations.of(context).translate('force_delete_label'),
                style: TextStyle(color: theme.popoverForeground, fontSize: 14),
              ),
              subtitle: Text(
                AppLocalizations.of(context).translate('force_delete_desc'),
                style: TextStyle(color: theme.mutedForeground, fontSize: 12),
              ),
              value: _forceDelete,
              onChanged: (bool? value) {
                setState(() {
                  _forceDelete = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: theme.destructive,
              contentPadding: EdgeInsets.zero,
            ),
            if (_apiErrorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  _apiErrorMessage!,
                  style: TextStyle(color: theme.destructive, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).translate('cancel')),
        ),
        ElevatedButton.icon(
          icon: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.destructiveForeground,
                  ),
                )
              : const Icon(Icons.delete_forever_rounded, size: 18),
          label: Text(
            isLoading
                ? '${AppLocalizations.of(context).translate('processing')}...'
                : AppLocalizations.of(context).translate('delete'),
          ),
          onPressed: () => _confirmDelete(isLoading),
          style:
              ElevatedButton.styleFrom(
                backgroundColor: theme.destructive,
                foregroundColor: theme.destructiveForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (states.contains(MaterialState.disabled)) {
                    return theme.destructive.withOpacity(0.5);
                  }
                  return theme.destructive;
                }),
              ),
        ),
      ],
    );
  }
}
