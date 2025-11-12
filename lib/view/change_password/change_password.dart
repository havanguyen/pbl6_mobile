import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:provider/provider.dart';

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
          _snackbarService.showSuccess('Đổi mật khẩu thành công!');
          Navigator.of(context).pop();
        } else {
          _snackbarService.showError(
              'Đổi mật khẩu thất bại. Vui lòng kiểm tra lại mật khẩu hiện tại.');
        }
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 8 ||
        !value.contains(RegExp(r'[a-zA-Z]')) ||
        !value.contains(RegExp(r'[0-9]'))) {
      return 'Mật khẩu tối thiểu 8 ký tự, có ít nhất 1 chữ cái và 1 số';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi mật khẩu'),
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
                'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới của bạn.',
                style: TextStyle(
                    fontSize: 15, color: context.theme.mutedForeground),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                key: const ValueKey('change_pass_current_field'),
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                style: TextStyle(color: context.theme.textColor),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon:
                  Icon(Icons.lock_outline, color: context.theme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: context.theme.mutedForeground,
                    ),
                    onPressed: () => setState(
                            () => _obscureCurrentPassword = !_obscureCurrentPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: context.theme.input,
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Vui lòng nhập mật khẩu hiện tại'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('change_pass_new_field'),
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                style: TextStyle(color: context.theme.textColor),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
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
                            () => _obscureNewPassword = !_obscureNewPassword),
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
                  labelText: 'Xác nhận mật khẩu mới',
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  prefixIcon:
                  Icon(Icons.lock_clock, color: context.theme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: context.theme.mutedForeground,
                    ),
                    onPressed: () => setState(() =>
                    _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: context.theme.input,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu mới';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
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
                    : const Text(
                  'Đổi mật khẩu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}