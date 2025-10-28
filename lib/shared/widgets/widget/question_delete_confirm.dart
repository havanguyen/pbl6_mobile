import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/question/question_vm.dart';
import 'package:provider/provider.dart';
import '../../../view_model/location_work_management/snackbar_service.dart';

class QuestionDeleteConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> question;
  final VoidCallback onDeleteSuccess;
  final SnackbarService snackbarService;

  const QuestionDeleteConfirmationDialog({
    super.key,
    required this.question,
    required this.onDeleteSuccess,
    required this.snackbarService,
  });

  @override
  State<QuestionDeleteConfirmationDialog> createState() =>
      _QuestionDeleteConfirmationDialogState();
}

class _QuestionDeleteConfirmationDialogState
    extends State<QuestionDeleteConfirmationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteQuestion() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    final questionVm = context.read<QuestionVm>();
    final success = await questionVm.deleteQuestion(
      widget.question['id'],
      _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.snackbarService.showSuccess('Xóa câu hỏi thành công!');
        widget.onDeleteSuccess();
        Navigator.of(context).pop();
      } else {
        widget.snackbarService.showError(questionVm.error ?? 'Xóa thất bại');
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
          Icon(Icons.warning_amber_rounded, color: context.theme.destructive),
          const SizedBox(width: 10),
          Text(
            'Xác nhận xóa',
            style: TextStyle(color: context.theme.textColor),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn có chắc chắn muốn xóa câu hỏi "${widget.question['title']}" không?',
                style: TextStyle(color: context.theme.mutedForeground),
              ),
              const SizedBox(height: 8),
              Text(
                'Hành động này không thể hoàn tác.',
                style: TextStyle(
                  color: context.theme.destructive,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Vui lòng nhập mật khẩu của bạn để xác nhận:',
                style: TextStyle(
                    color: context.theme.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                style: TextStyle(color: context.theme.textColor),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  labelStyle: TextStyle(color: context.theme.mutedForeground),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: context.theme.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: context.theme.input,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: context.theme.mutedForeground,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 1) {
                    return 'Mật khẩu phải có ít nhất 1 ký tự';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Hủy', style: TextStyle(color: context.theme.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _deleteQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: context.theme.destructive,
            foregroundColor: context.theme.destructiveForeground,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Xóa'),
        ),
      ],
    );
  }
}