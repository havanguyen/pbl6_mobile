import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

class SpecialtyForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final Future<bool> Function({
  required String name,
  String? description,
  String? id,
  }) onSubmit;

  const SpecialtyForm({
    super.key,
    required this.isUpdate,
    this.initialData,
    required this.onSubmit,
  });

  @override
  State<SpecialtyForm> createState() => _SpecialtyFormState();
}

class _SpecialtyFormState extends State<SpecialtyForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData?['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        name: _nameController.text,
        description: _descriptionController.text,
      );
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('${widget.isUpdate ? 'Cập nhật' : 'Tạo'} chuyên khoa thất bại. Vui lòng thử lại.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Thành công', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text('${widget.isUpdate ? 'Cập nhật' : 'Tạo'} chuyên khoa thành công!', style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('OK', style: TextStyle(color: context.theme.primary)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Lỗi', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text(message, style: TextStyle(color: context.theme.popoverForeground)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Tên chuyên khoa',
                prefixIcon: Icon(Icons.medical_services, color: context.theme.primary),
                border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập tên chuyên khoa';
                if (value.length < 10 || value.length > 200) return 'Tên phải từ 10 đến 200 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: 'Mô tả',
                prefixIcon: Icon(Icons.description, color: context.theme.primary),
                border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              maxLines: 5,
              validator: (value) {
                if (value != null && value.isNotEmpty && (value.length < 10 || value.length > 1000)) {
                  return 'Mô tả phải từ 10 đến 1000 ký tự nếu nhập';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            CustomButtonBlue(
              onTap: _submitForm,
              text: _isLoading ? 'Đang ${widget.isUpdate ? 'cập nhật' : 'tạo'}...' : '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} chuyên khoa',
            ),
          ],
        ),
      ),
    );
  }
}