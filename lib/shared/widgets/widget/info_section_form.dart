import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import 'doctor_form.dart';

class InfoSectionForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final String specialtyId;
  final Future<bool> Function({
  required String name,
  required String content,
  String? id,
  }) onSubmit;
  final VoidCallback? onSuccess;

  const InfoSectionForm({
    super.key,
    required this.isUpdate,
    this.initialData,
    required this.specialtyId,
    required this.onSubmit,
    this.onSuccess,
  });

  @override
  State<InfoSectionForm> createState() => _InfoSectionFormState();
}

class _InfoSectionFormState extends State<InfoSectionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late quill.QuillController _contentController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialData?['name'] ?? '');
    _contentController = quill.QuillController.basic();
    final initialContent = widget.initialData?['content'];
    if (initialContent != null && initialContent.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(initialContent));
        _contentController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        final doc = quill.Document()..insert(0, initialContent);
        _contentController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final plainTextContent = _contentController.document.toPlainText().trim();
      if (plainTextContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nội dung không được để trống')),
        );
        return false;
      }
      final jsonContent =
      jsonEncode(_contentController.document.toDelta().toJson());
      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        name: _nameController.text,
        content: jsonContent,
      );
      if (success) {
        widget.onSuccess?.call();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
      return success;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Tên phần thông tin',
              prefixIcon: Icon(Icons.title, color: context.theme.primary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập tên';
              }
              if (value.length < 10 || value.length > 200) {
                return 'Tên phải từ 10 đến 200 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Nội dung',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.theme.textColor),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: context.theme.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  quill.QuillSimpleToolbar(
                    controller: _contentController,
                    config: const quill.QuillSimpleToolbarConfig(),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: quill.QuillEditor(
                        controller: _contentController,
                        focusNode: _focusNode,
                        scrollController: _scrollController,
                        config: quill.QuillEditorConfig(
                          padding: const EdgeInsets.all(8),
                          embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          AnimatedSubmitButton(
            onSubmit: _submitForm,
            idleText: '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} phần thông tin',
            loadingText: 'Đang xử lý...',
          ),
        ],
      ),
    );
  }
}