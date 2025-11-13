import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/view_model/patient/patient_vm.dart';
import 'package:provider/provider.dart';

class PatientDeleteConfirmDialog extends StatelessWidget {
  const PatientDeleteConfirmDialog({
    super.key,
    required this.patient,
  });

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác nhận Xóa'),
      content: Text('Bạn có chắc chắn muốn xóa bệnh nhân ${patient.fullName}?'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            context.read<PatientVm>().deletePatient(patient.id);
            Navigator.of(context).pop();
          },
          child: const Text(
            'Xóa',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}