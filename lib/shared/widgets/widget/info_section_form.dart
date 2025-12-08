import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'doctor_form.dart';

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
  final HtmlEditorController _controller = HtmlEditorController();
  late AnimationController _animationController;
  String _initialContent = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialData?['name'] ?? '',
    );

    final initialContent = widget.initialData?['content'];
    if (initialContent != null && initialContent.isNotEmpty) {
      try {
        final json = jsonDecode(initialContent);
        // If it decodes as JSON list, assume it's a Quill Delta
        if (json is List) {
          final converter = QuillDeltaToHtmlConverter(List.castFrom(json));
          _initialContent = converter.convert();
        } else {
          _initialContent = initialContent;
        }
      } catch (e) {
        // Not JSON, assume HTML/Text
        _initialContent = initialContent;
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
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final finalContent = await _controller.getText();

      if (finalContent.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                ).translate('info_section_content_required'),
              ),
            ),
          );
        }
        return false;
      }

      final success = await widget.onSubmit(
        id: widget.initialData?['id'],
        name: _nameController.text,
        content: finalContent,
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
                clipBehavior: Clip.antiAlias,
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
                child: HtmlEditor(
                  controller: _controller,
                  htmlEditorOptions: HtmlEditorOptions(
                    hint: AppLocalizations.of(
                      context,
                    ).translate('info_section_content_hint'),
                    initialText: _initialContent,
                  ),
                  htmlToolbarOptions: HtmlToolbarOptions(
                    toolbarPosition: ToolbarPosition.aboveEditor,
                    toolbarType: ToolbarType.nativeScrollable,
                    defaultToolbarButtons: [
                      const StyleButtons(),
                      const FontSettingButtons(),
                      const FontButtons(),
                      const ColorButtons(),
                      const ListButtons(),
                      const ParagraphButtons(),
                      const InsertButtons(),
                      const OtherButtons(
                        codeview: false,
                        fullscreen: false,
                        help: false,
                      ),
                    ],
                    customToolbarButtons: [
                      _CodeViewToggleButton(controller: _controller),
                    ],
                  ),
                  otherOptions: OtherOptions(
                    height: 400,
                    decoration: BoxDecoration(
                      color: theme.input,
                      borderRadius: BorderRadius.circular(12),
                    ),
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

class _CodeViewToggleButton extends StatefulWidget {
  final HtmlEditorController controller;

  const _CodeViewToggleButton({required this.controller});

  @override
  State<_CodeViewToggleButton> createState() => _CodeViewToggleButtonState();
}

class _CodeViewToggleButtonState extends State<_CodeViewToggleButton> {
  bool _isLoading = false;
  bool _isCodeView = false;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      icon: Icon(
        _isCodeView ? Icons.visibility_outlined : Icons.code,
        color: Colors.black87,
      ),
      onPressed: () async {
        setState(() => _isLoading = true);
        try {
          await Future.delayed(const Duration(milliseconds: 100));
          widget.controller.toggleCodeView();
          await Future.delayed(const Duration(milliseconds: 700));
          setState(() => _isCodeView = !_isCodeView);
        } catch (e) {
          debugPrint('Error toggling code view: $e');
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      },
      tooltip: 'Switch to ${_isCodeView ? 'Visual' : 'HTML'} View',
    );
  }
}
