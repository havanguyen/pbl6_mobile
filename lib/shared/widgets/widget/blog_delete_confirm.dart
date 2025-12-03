import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

import '../../../view_model/location_work_management/snackbar_service.dart';

class BlogDeleteConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> blog;
  final VoidCallback onDeleteSuccess;
  final SnackbarService snackbarService;

  const BlogDeleteConfirmationDialog({
    super.key,
    required this.blog,
    required this.onDeleteSuccess,
    required this.snackbarService,
  });

  @override
  State<BlogDeleteConfirmationDialog> createState() =>
      _BlogDeleteConfirmationDialogState();
}

class _BlogDeleteConfirmationDialogState
    extends State<BlogDeleteConfirmationDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;
  String? _apiErrorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
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
      _isDeleting = true;
      _apiErrorMessage = null;
    });

    final provider = Provider.of<BlogVm>(context, listen: false);
    final success = await provider.deleteBlog(widget.blog['id'], password);

    if (mounted) {
      setState(() => _isDeleting = false);
      if (success) {
        Navigator.of(context).pop();
        widget.onDeleteSuccess();
        widget.snackbarService.showSuccess(
          AppLocalizations.of(context).translate('delete_blog_success'),
        );
      } else {
        setState(() {
          _apiErrorMessage =
              provider.error ??
              AppLocalizations.of(context).translate('delete_blog_failed');
          provider.clearError();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.theme.popover,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ), // Rounded corners
      title: Row(
        // Add icon to title
        children: [
          Icon(Icons.warning_amber_rounded, color: context.theme.destructive),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).translate('confirm_delete_blog_title'),
            style: TextStyle(
              color: context.theme.popoverForeground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        // Allow scrolling if content overflows
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // Align text left
          children: [
            Text(
              AppLocalizations.of(
                context,
              ).translate('confirm_delete_blog_message'),
              style: TextStyle(
                color: context.theme.popoverForeground.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"${widget.blog['title']}"?',
              style: TextStyle(
                color: context.theme.popoverForeground,
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
              style: TextStyle(color: context.theme.textColor),
              autofocus: true, // Focus password field automatically
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).translate('enter_password_confirm'),
                labelStyle: TextStyle(color: context.theme.mutedForeground),
                hintText: AppLocalizations.of(
                  context,
                ).translate('password_confirm_hint'),
                hintStyle: TextStyle(
                  color: context.theme.mutedForeground.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: context.theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.theme.primary,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.theme.destructive,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: context.theme.destructive,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: context.theme.input,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                isDense: true, // Make field slightly smaller
              ),
              onChanged: (_) {
                if (_apiErrorMessage != null) {
                  setState(() => _apiErrorMessage = null);
                }
              },
              onSubmitted: (_) => _confirmDelete(),
            ),
            if (_apiErrorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                // Add padding for error message
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  _apiErrorMessage!,
                  style: TextStyle(
                    color: context.theme.destructive,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ), // Adjust action button padding
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: context.theme.mutedForeground,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(AppLocalizations.of(context).translate('cancel')),
        ),
        ElevatedButton.icon(
          // Use ElevatedButton for delete action
          icon: _isDeleting
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.theme.destructiveForeground,
                  ),
                )
              : Icon(Icons.delete_forever_rounded, size: 18),
          label: Text(
            _isDeleting
                ? '${AppLocalizations.of(context).translate('processing')}...'
                : AppLocalizations.of(context).translate('delete'),
          ),
          onPressed: _isDeleting ? null : _confirmDelete,
          style:
              ElevatedButton.styleFrom(
                backgroundColor: context.theme.destructive,
                foregroundColor: context.theme.destructiveForeground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (states.contains(MaterialState.disabled)) {
                    return context.theme.destructive.withOpacity(0.5);
                  }
                  return context.theme.destructive;
                }),
              ),
        ),
      ],
    );
  }
}
