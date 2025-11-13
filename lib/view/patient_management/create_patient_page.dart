import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/patient_form.dart';
import 'package:pbl6mobile/view_model/patient/patient_vm.dart';
import 'package:provider/provider.dart';

class CreatePatientPage extends StatefulWidget {
  const CreatePatientPage({super.key});

  @override
  State<CreatePatientPage> createState() => _CreatePatientPageState();
}

class _CreatePatientPageState extends State<CreatePatientPage> {
  bool _isLoading = false;

  void _handleSubmit(Map<String, dynamic> data) async {
    setState(() {
      _isLoading = true;
    });

    final patientVm = context.read<PatientVm>();
    final success = await patientVm.addPatient(data);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo bệnh nhân thành công')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tạo bệnh nhân thất bại')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Bệnh nhân mới'),
        backgroundColor: context.theme.blue,
      ),
      body: PatientForm(
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
      ),
    );
  }
}