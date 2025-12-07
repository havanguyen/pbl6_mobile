import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/patient_form.dart';
import 'package:pbl6mobile/view_model/patient/patient_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class UpdatePatientPage extends StatefulWidget {
  final Patient patient;
  const UpdatePatientPage({super.key, required this.patient});

  @override
  State<UpdatePatientPage> createState() => _UpdatePatientPageState();
}

class _UpdatePatientPageState extends State<UpdatePatientPage> {
  bool _isLoading = false;

  void _handleSubmit(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final patientVm = context.read<PatientVm>();
    final success = await patientVm.editPatient(widget.patient.id, data);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.theme.green,
            content: Text(
              AppLocalizations.of(context).translate('update_patient_success'),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.theme.destructive,
            content: Text(
              AppLocalizations.of(context).translate('update_patient_failed'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('update_patient_title'),
        ),
        backgroundColor: context.theme.blue,
      ),
      body: PatientForm(
        patient: widget.patient,
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
      ),
    );
  }
}
