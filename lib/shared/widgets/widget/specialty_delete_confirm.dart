import 'package:flutter/material.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import '../../../view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class DeleteSpecialtyConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> specialty;
  final VoidCallback onDeleteSuccess;
  final SnackbarService snackbarService;

  const DeleteSpecialtyConfirmationDialog({
    super.key,
    required this.specialty,
    required this.onDeleteSuccess,
    required this.snackbarService,
  });

  @override
  State<DeleteSpecialtyConfirmationDialog> createState() =>
      _DeleteSpecialtyConfirmationDialogState();
}

class _DeleteSpecialtyConfirmationDialogState
    extends State<DeleteSpecialtyConfirmationDialog> {
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

    final provider = Provider.of<SpecialtyVm>(context, listen: false);
    final success = await provider.deleteSpecialty(
      widget.specialty['id'],
      password,
    );

    if (mounted) {
      setState(() => _isDeleting = false);
      if (success) {
        Navigator.of(context).pop();
        widget.onDeleteSuccess();
        widget.snackbarService.showSuccess(
          AppLocalizations.of(context).translate('delete_specialty_success'),
        );
      } else {
        setState(() {
          _apiErrorMessage = AppLocalizations.of(
            context,
          ).translate('delete_specialty_failed');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.theme.popover,
      title: Text(
        AppLocalizations.of(
          context,
        ).translate('confirm_delete_specialty_title'),
        style: TextStyle(color: context.theme.popoverForeground),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${AppLocalizations.of(context).translate('confirm_delete_specialty_message')}: ${widget.specialty['name']}?',
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
              ).translate('enter_password_confirm'),
              labelStyle: TextStyle(color: context.theme.mutedForeground),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: context.theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: context.theme.ring),
              ),
              filled: true,
              fillColor: context.theme.input,
            ),
            onChanged: (_) => setState(() => _apiErrorMessage = null),
            onSubmitted: (_) => _confirmDelete(),
          ),
          if (_apiErrorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _apiErrorMessage!,
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
