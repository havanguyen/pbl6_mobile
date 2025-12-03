import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'doctor_form.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class InfoSectionForm extends StatefulWidget {
  final bool isUpdate;
  final Map<String, dynamic>? initialData;
  final String specialtyId;
  final Future<bool> Function({
    required String name,
    required String content,
    String? id,
  })
  onSubmit;
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

class _InfoSectionFormState extends State<InfoSectionForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late quill.QuillController _contentController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData?['name'] ?? '',
    );
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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final plainTextContent = _contentController.document.toPlainText().trim();
      if (plainTextContent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              ).translate('info_section_content_required'),
            ),
          ),
        );
        return false;
      }
      final jsonContent = jsonEncode(
        _contentController.document.toDelta().toJson(),
      );
      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        name: _nameController.text,
        content: jsonContent,
      );
      if (success) {
        widget.onSuccess?.call();
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
      return success;
    }
    return false;
  }

  // Helper widget để tạo hiệu ứng động
  Widget _buildAnimatedWrapper({required Widget child, required int index}) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2 * index, 1.0, curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2 * index, 1.0, curve: Curves.easeOut),
              ),
            ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildAnimatedWrapper(
              index: 1,
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('info_section_name_label'),
                  hintText: AppLocalizations.of(
                    context,
                  ).translate('info_section_name_hint'),
                  prefixIcon: Icon(Icons.title_rounded, color: theme.primary),
                  filled: true,
                  fillColor: theme.input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primary, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    ).translate('info_section_name_required');
                  }
                  if (value.length < 10 || value.length > 200) {
                    return AppLocalizations.of(
                      context,
                    ).translate('info_section_name_length_error');
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedWrapper(
              index: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.border),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.popover.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.input,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        child: quill.QuillSimpleToolbar(
                          controller: _contentController,
                          config: const quill.QuillSimpleToolbarConfig(
                            toolbarSize: 20,
                            toolbarSectionSpacing: 2,
                            showAlignmentButtons: true,
                            showFontSize: false,
                            showDividers: false,
                            multiRowsDisplay: false,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Container(
                        height: 300,
                        color: theme.input,
                        padding: const EdgeInsets.all(5),
                        child: quill.QuillEditor(
                          controller: _contentController,
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildAnimatedWrapper(
              index: 3,
              child: Center(
                child: AnimatedSubmitButton(
                  onSubmit: _submitForm,
                  idleText: widget.isUpdate
                      ? '💾 ${AppLocalizations.of(context).translate('update_btn')}'
                      : '➕ ${AppLocalizations.of(context).translate('create_btn')}',
                  loadingText: AppLocalizations.of(
                    context,
                  ).translate('processing'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
