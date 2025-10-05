import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../../model/entities/work_location.dart';
import '../../../model/services/remote/work_location_service.dart';
import '../../../view_model/location_work_management/snackbar_service.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final WorkLocation location;
  final VoidCallback onDeleteSuccess;
  final SnackbarService snackbarService;

  const DeleteConfirmationDialog({
    super.key,
    required this.location,
    required this.onDeleteSuccess,
    required this.snackbarService
  });

  @override
  State<DeleteConfirmationDialog> createState() => DeleteConfirmationDialogState();
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
      _errorMessage = 'Vui lòng nhập mật khẩu';
      return false;
    }
    if (password.length < 6) {
      _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự';
      return false;
    }
    if (password.length > 50) {
      _errorMessage = 'Mật khẩu không được vượt quá 50 ký tự';
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
          widget.snackbarService.showSuccess('Xóa địa điểm thành công!');
        } else {
          setState(() {
            _apiErrorMessage = 'Xóa thất bại. Kiểm tra mật khẩu hoặc thử lại.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
      }

      String errorMessage = 'Có lỗi xảy ra. Vui lòng thử lại.';

      if (e.toString().contains('Validation failed') ||
          e.toString().contains('400') ||
          e.toString().contains('isLength')) {
        errorMessage = 'Mật khẩu phải từ 6 đến 50 ký tự';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Mật khẩu không chính xác';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        errorMessage = 'Bạn không có quyền thực hiện hành động này';
      } else if (e.toString().contains('ThrottlerException')) {
        errorMessage = 'Quá nhiều yêu cầu. Vui lòng thử lại sau!';
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
        'Xác nhận xóa',
        style: TextStyle(color: context.theme.popoverForeground),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bạn có chắc chắn muốn xóa địa điểm: ${widget.location.name}?',
            style: TextStyle(color: context.theme.popoverForeground),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: context.theme.textColor),
            decoration: InputDecoration(
              labelText: 'Nhập mật khẩu Admin/Super Admin',
              labelStyle: TextStyle(color: context.theme.mutedForeground),
              hintText: 'Mật khẩu từ 6-50 ký tự',
              hintStyle: TextStyle(color: context.theme.mutedForeground.withOpacity(0.7)),
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
              if ((_errorMessage != null || _apiErrorMessage != null) && value.isNotEmpty) {
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
              style: TextStyle(
                color: context.theme.destructive,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: Text('Hủy', style: TextStyle(color: context.theme.mutedForeground)),
        ),
        _isDeleting
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : TextButton(
          onPressed: _confirmDelete,
          child: Text('Xóa', style: TextStyle(color: context.theme.destructive)),
        ),
      ],
    );
  }
}