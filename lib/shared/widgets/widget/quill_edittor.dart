import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

class QuillEditor extends StatelessWidget {
  final String label;
  final quill.QuillController controller;
  final bool isReadOnly;

  const QuillEditor({super.key,
    required this.label,
    required this.controller,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(12),
            color: isReadOnly ? theme.muted.withOpacity(0.3) : theme.card,
            boxShadow: [
              BoxShadow(
                color: theme.textColor.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                if (!isReadOnly)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.input,
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: quill.QuillSimpleToolbar(
                      controller: controller,
                      config: const quill.QuillSimpleToolbarConfig(
                        toolbarSize: 24,
                        toolbarSectionSpacing: 4,
                        showAlignmentButtons: true,
                        showFontSize: false,
                        showSubscript: false,
                        showSuperscript: false,
                        showInlineCode: false,
                        showDividers: true,
                        multiRowsDisplay: false,
                        showBoldButton: true,
                        showItalicButton: true,
                        showUnderLineButton: true,
                        showStrikeThrough: true,
                        showClearFormat: true,
                        showHeaderStyle: true,
                        showListBullets: true,
                        showListNumbers: true,
                        showListCheck: true,
                        showCodeBlock: false,
                        showQuote: true,
                        showIndent: true,
                        showLink: true,
                        showUndo: true,
                        showRedo: true,
                      ),
                    ),
                  ),
                if (!isReadOnly) const Divider(height: 1),
                Container(
                  constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
                  color: isReadOnly ? theme.muted.withOpacity(0.3) : theme.input,
                  padding: const EdgeInsets.all(12),
                  child: quill.QuillEditor.basic(
                    controller: controller,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}