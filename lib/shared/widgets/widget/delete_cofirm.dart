import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../../model/entities/work_location.dart';
import '../../../model/services/remote/work_location_service.dart';
import '../../../view_model/location_work_management/snackbar_service.dart';
import '../../localization/app_localizations.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final WorkLocation location;
  final VoidCallback onDeleteSuccess;
  final SnackbarService snackbarService;

  const DeleteConfirmationDialog({
    super.key,
    required this.location,
    required this.onDeleteSuccess,
    required this.snackbarService,
  });

  @override
  State<DeleteConfirmationDialog> createState() =>
      DeleteConfirmationDialogState();
}

class DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isDeleting = false;
  String? _errorMessage;
  String? _apiErrorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    if (password.isEmpty) {
      _errorMessage = AppLocalizations.of(
        context,
      ).translate('password_required');
      return false;
    }
    if (password.length < 6) {
      _errorMessage = AppLocalizations.of(
        context,
      ).translate('password_min_length');
      return false;
    }
    if (password.length > 50) {
      _errorMessage = AppLocalizations.of(
        context,
      ).translate('password_max_length');
      return false;
    }
    _errorMessage = null;
    return true;
  }

  Future<void> _confirmDelete() async {
    final password = _passwordController.text.trim();
    setState(() {
      _apiErrorMessage = null;
    });
    if (!_validatePassword(password)) {
      setState(() {
        _apiErrorMessage = _errorMessage;
      });
      return;
    }

    setState(() => _isDeleting = true);

    try {
      final success = await LocationWorkService.deleteLocation(
        widget.location.id,
        password: password,
      );

      if (mounted) {
        setState(() => _isDeleting = false);

        if (success) {
          Navigator.of(context).pop();
          widget.onDeleteSuccess();
          widget.snackbarService.showSuccess(
            AppLocalizations.of(context).translate('delete_location_success'),
          );
        } else {
          setState(() {
            _apiErrorMessage = AppLocalizations.of(
              context,
            ).translate('delete_location_failed');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
      }

      String errorMessage = AppLocalizations.of(
        context,
      ).translate('error_occurred_retry');

      if (e.toString().contains('Validation failed') ||
          e.toString().contains('400') ||
          e.toString().contains('isLength')) {
        errorMessage = AppLocalizations.of(
          context,
        ).translate('password_length_error');
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage = AppLocalizations.of(
          context,
        ).translate('incorrect_password');
      } else if (e.toString().contains('403') ||
          e.toString().contains('Forbidden')) {
        errorMessage = AppLocalizations.of(
          context,
        ).translate('forbidden_action');
      } else if (e.toString().contains('ThrottlerException')) {
        errorMessage = AppLocalizations.of(
          context,
        ).translate('too_many_requests');
      }
      if (mounted) {
        setState(() {
          _apiErrorMessage = errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.theme.popover,
      title: Text(
        AppLocalizations.of(context).translate('confirm_delete_title'),
        style: TextStyle(color: context.theme.popoverForeground),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${AppLocalizations.of(context).translate('confirm_delete_location_message')}: ${widget.location.name}?',
            style: TextStyle(color: context.theme.popoverForeground),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: context.theme.textColor),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(
                context,
              ).translate('enter_super_admin_password'),
              labelStyle: TextStyle(color: context.theme.mutedForeground),
              hintText: AppLocalizations.of(context).translate('password_hint'),
              hintStyle: TextStyle(
                color: context.theme.mutedForeground.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: context.theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: context.theme.ring),
              ),
              filled: true,
              fillColor: context.theme.input,
              errorText: _errorMessage,
            ),
            onChanged: (value) {
              if ((_errorMessage != null || _apiErrorMessage != null) &&
                  value.isNotEmpty) {
                setState(() {
                  _errorMessage = null;
                  _apiErrorMessage = null;
                });
              }
            },
            onSubmitted: (_) => _confirmDelete(),
          ),
          if (_apiErrorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.theme.destructive.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.theme.destructive.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: context.theme.destructive,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _apiErrorMessage!,
                      style: TextStyle(
                        color: context.theme.destructive,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_errorMessage != null && _apiErrorMessage == null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: context.theme.destructive, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context).translate('cancel'),
            style: TextStyle(color: context.theme.mutedForeground),
          ),
        ),
        _isDeleting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(
                onPressed: _confirmDelete,
                child: Text(
                  AppLocalizations.of(context).translate('delete'),
                  style: TextStyle(color: context.theme.destructive),
                ),
              ),
      ],
    );
  }
}
