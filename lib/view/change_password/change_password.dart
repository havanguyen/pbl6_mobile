import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  late final SnackbarService _snackbarService;

  @override
  void initState() {
    super.initState();
    _snackbarService = Provider.of<SnackbarService>(context, listen: false);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final currentPassword = _currentPasswordController.text;
      final newPassword = _newPasswordController.text;

      final success = await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        if (success) {
          _snackbarService.showSuccess(
            AppLocalizations.of(context).translate('change_password_success'),
          );
          Navigator.of(context).pop();
        } else {
          _snackbarService.showError(
            AppLocalizations.of(context).translate('change_password_failed'),
          );
        }
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).translate('password_required');
    }
    if (value.length < 8 ||
        !value.contains(RegExp(r'[a-zA-Z]')) ||
        !value.contains(RegExp(r'[0-9]'))) {
      return AppLocalizations.of(context).translate('password_invalid');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('change_password')),
        elevation: 0,
        backgroundColor: context.theme.primary,
        titleTextStyle: TextStyle(
          color: context.theme.primaryForeground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: context.theme.primaryForeground),
      ),
      backgroundColor: context.theme.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                ).translate('change_password_instruction'),
                style: TextStyle(
                  fontSize: 15,
                  color: context.theme.mutedForeground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                key: const ValueKey('change_pass_current_field'),
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                style: TextStyle(color: context.theme.textColor),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('current_password'),
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: context.theme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: context.theme.mutedForeground,
                    ),
                    onPressed: () => setState(
                      () => _obscureCurrentPassword = !_obscureCurrentPassword,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: context.theme.input,
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? AppLocalizations.of(
                        context,
                      ).translate('current_password_required')
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('change_pass_new_field'),
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                style: TextStyle(color: context.theme.textColor),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('new_password'),
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon: Icon(Icons.lock, color: context.theme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: context.theme.mutedForeground,
                    ),
                    onPressed: () => setState(
                      () => _obscureNewPassword = !_obscureNewPassword,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: context.theme.input,
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('change_pass_confirm_field'),
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                style: TextStyle(color: context.theme.textColor),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('confirm_new_password'),
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon: Icon(
                    Icons.lock_clock,
                    color: context.theme.primary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: context.theme.mutedForeground,
                    ),
                    onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: context.theme.input,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    ).translate('confirm_new_password_required');
                  }
                  if (value != _newPasswordController.text) {
                    return AppLocalizations.of(
                      context,
                    ).translate('password_mismatch');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                key: const ValueKey('change_pass_submit_button'),
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primary,
                  foregroundColor: context.theme.primaryForeground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(
                          context,
                        ).translate('change_password'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
