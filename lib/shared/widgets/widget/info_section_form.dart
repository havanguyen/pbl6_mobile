import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

import '../../services/store.dart';

class InfoSectionForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final String specialtyId;
  final Future<bool> Function({
  required String name,
  required String content,
  String? id,
  }) onSubmit;

  const InfoSectionForm({
    super.key,
    required this.isUpdate,
    this.initialData,
    required this.specialtyId,
    required this.onSubmit,
  });

  @override
  State<InfoSectionForm> createState() => _InfoSectionFormState();
}

class _InfoSectionFormState extends State<InfoSectionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final HtmlEditorController _controller = HtmlEditorController();
  bool _isLoading = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    isDarkMode().then((value) => setState(() => _isDarkMode = value));
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    if (widget.initialData?['content'] != null) {
      _controller.setText(widget.initialData?['content']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final content = await _controller.getText();
      if (content.isEmpty) {
        _showErrorDialog('Vui lòng nhập nội dung');
        return;
      }
      setState(() => _isLoading = true);
      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        name: _nameController.text,
        content: content,
      );
      setState(() => _isLoading = false);
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('${widget.isUpdate ? 'Cập nhật' : 'Tạo'} phần thông tin thất bại. Vui lòng thử lại.');
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Thành công', style: TextStyle(color: context.theme.popoverForeground)),
        content: Text('${widget.isUpdate ? 'Cập nhật' : 'Tạo'} phần thông tin thành công!', style: TextStyle(color: context.theme.popoverForeground)),
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
  Future<bool> isDarkMode () async {
    final themeModeString = await Store.getThemeMode();
    switch (themeModeString) {
      case 'dark':
        return true;
      default:
        return false;
    }
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
                labelText: 'Tên phần thông tin',
                prefixIcon: Icon(Icons.info, color: context.theme.primary),
                border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Vui lòng nhập tên phần thông tin';
                return null;
              },
            ),
            const SizedBox(height: 16),
            HtmlEditor(
              controller: _controller,
              htmlEditorOptions: HtmlEditorOptions(
                hint: 'Nội dung...',
                darkMode: _isDarkMode,
              ),
              htmlToolbarOptions: HtmlToolbarOptions(
                toolbarPosition: ToolbarPosition.aboveEditor,
                defaultToolbarButtons: [
                  FontButtons(),
                  StyleButtons(),
                  FontSettingButtons(),
                  ColorButtons(),
                  ListButtons(),
                  ParagraphButtons(),
                  InsertButtons(video: true, audio: true, otherFile: true),
                ],
              ),
            ),
            const SizedBox(height: 32),
            CustomButtonBlue(
              onTap: _submitForm,
              text: _isLoading ? 'Đang ${widget.isUpdate ? 'cập nhật' : 'tạo'}...' : '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} phần thông tin',
            ),
          ],
        ),
      ),
    );
  }
}