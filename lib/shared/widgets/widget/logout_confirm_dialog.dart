import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class LogoutConfirmationDialog extends StatefulWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  State<LogoutConfirmationDialog> createState() =>
      _LogoutConfirmationDialogState();
}

class _LogoutConfirmationDialogState extends State<LogoutConfirmationDialog> {
  bool _isLoading = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    final success = await AuthService.logout();
    if (success && mounted) {
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(Routes.login, (Route<dynamic> route) => false);
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('logout_failed'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.theme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.logout, color: context.theme.destructive),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context).translate('logout_confirmation_title'),
            style: TextStyle(
              color: context.theme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        AppLocalizations.of(context).translate('logout_confirmation_message'),
        style: TextStyle(color: context.theme.mutedForeground),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context).translate('cancel'),
            style: TextStyle(color: context.theme.mutedForeground),
          ),
        ),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.destructive,
                  foregroundColor: context.theme.destructiveForeground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(AppLocalizations.of(context).translate('logout')),
              ),
      ],
    );
  }
}
