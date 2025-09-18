import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ChangePasswordPageState createState() => ChangePasswordPageState();
}

class ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final success = await AuthService.changePassword(
        currentPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      setState(() => _isLoading = false);

      if (success) {
        _showSuccessDialog('Đổi mật khẩu thành công!');
      } else {
        final isLoggedIn = await AuthService.isLoggedIn();
        if (!isLoggedIn && context.mounted) {
          _showErrorDialog('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
          Navigator.pushReplacementNamed(context, Routes.login);
        } else if (context.mounted) {
          _showErrorDialog('Đổi mật khẩu thất bại. Vui lòng kiểm tra lại.');
        }
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành công'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        title: Text(
          'Đổi mật khẩu',
          style: TextStyle(color: context.theme.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  prefixIcon: Icon(Icons.lock, color: context.theme.blue),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOldPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscureOldPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu cũ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_outline, color: context.theme.blue),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscureNewPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (value.length < 8 || !value.contains(RegExp(r'[a-zA-Z]')) || !value.contains(RegExp(r'[0-9]'))) {
                    return 'Mật khẩu tối thiểu 8 ký tự, có ít nhất 1 chữ cái và 1 số';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: Icon(Icons.lock_outline, color: context.theme.blue),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              CustomButtonBlue(
                onTap:  _changePassword,
                text: _isLoading ? 'Đang xử lý...' : 'Đổi mật khẩu',
              ),
            ],
          ),
        ),
      ),
    );
  }
}