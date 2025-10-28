import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:provider/provider.dart';

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
        _apiErrorMessage = 'Vui lòng nhập mật khẩu.';
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
        widget.snackbarService.showSuccess('Xóa danh mục thành công!');
      } else {
        setState(() {
          _apiErrorMessage = provider.categoryError ??
              'Xóa thất bại. Kiểm tra mật khẩu hoặc thử lại.';
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
            'Xác nhận xóa',
            style: TextStyle(
                color: theme.popoverForeground, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa danh mục:',
              style: TextStyle(
                  color: theme.popoverForeground.withOpacity(0.8),
                  fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '"${widget.category.name}"?',
              style: TextStyle(
                  color: theme.popoverForeground,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
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
                labelText: 'Nhập mật khẩu của bạn',
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
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                'Buộc xóa (Force Delete)',
                style: TextStyle(color: theme.popoverForeground, fontSize: 14),
              ),
              subtitle: Text(
                'Xóa danh mục này ngay cả khi nó đang được liên kết với các bài viết.',
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
            ]
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton.icon(
          icon: isLoading
              ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: theme.destructiveForeground))
              : const Icon(Icons.delete_forever_rounded, size: 18),
          label: Text(isLoading ? 'Đang xóa...' : 'Xóa'),
          onPressed: () => _confirmDelete(isLoading),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.destructive,
            foregroundColor: theme.destructiveForeground,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ).copyWith(
            backgroundColor: MaterialStateProperty.resolveWith<Color?>((states) {
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