import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/view_model/patient/patient_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class PatientDeleteConfirmDialog extends StatelessWidget {
  const PatientDeleteConfirmDialog({super.key, required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocalizations.of(context).translate('confirm_delete_title'),
      ),
      content: Text(
        '${AppLocalizations.of(context).translate('confirm_delete_patient_named')}${patient.fullName}?',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).translate('cancel')),
        ),
        TextButton(
          onPressed: () {
            context.read<PatientVm>().deletePatient(patient.id);
            Navigator.of(context).pop();
          },
          child: Text(
            AppLocalizations.of(context).translate('delete'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
