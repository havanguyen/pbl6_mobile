import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/question/question_vm.dart';
import 'package:provider/provider.dart';
import '../../../view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

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
  bool _isLoading = false;

  Future<void> _deleteQuestion() async {
    setState(() => _isLoading = true);
    final questionVm = context.read<QuestionVm>();
    final success = await questionVm.deleteQuestion(widget.question['id']);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        widget.snackbarService.showSuccess(
          AppLocalizations.of(context).translate('delete_question_success'),
        );
        widget.onDeleteSuccess();
        Navigator.of(context).pop();
      } else {
        widget.snackbarService.showError(
          questionVm.error ??
              AppLocalizations.of(context).translate('delete_failed'),
        );
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
            AppLocalizations.of(context).translate('confirm_delete'),
            style: TextStyle(color: context.theme.textColor),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context).translate('confirm_delete_question')} "${widget.question['title']}"?',
              style: TextStyle(color: context.theme.mutedForeground),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).translate('action_cannot_undo'),
              style: TextStyle(
                color: context.theme.destructive,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context).translate('cancel'),
            style: TextStyle(color: context.theme.grey),
          ),
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
              : Text(AppLocalizations.of(context).translate('delete')),
        ),
      ],
    );
  }
}
