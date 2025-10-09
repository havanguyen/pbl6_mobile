import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../shared/widgets/widget/doctor_form.dart';

class UpdateDoctorPage extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const UpdateDoctorPage({super.key, required this.doctor});

  String _convertDateFormat(String input) {
    try {
      if (input.contains('/')) {
        final parts = input.split('/');
        if (parts.length != 3) return input;
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      } else if (input.contains('-')) {
        return input;
      }
      return input;
    } catch (e) {
      return input;
    }
  }

  Future<bool> _onSubmit({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String dateOfBirth,
    required bool isMale,
    String? id,
  }) async {
    final convertedDate = _convertDateFormat(dateOfBirth);
    final success = await DoctorService.updateDoctor(
      id!,
      fullName: fullName,
      email: email,
      password: password.isEmpty ? null : password,
      phone: phone,
      dateOfBirth: convertedDate,
      isMale: isMale,
    );

    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        title: Text(
          'Chỉnh sửa tài khoản bác sĩ',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: context.theme.bg,
      body: DoctorForm(
        isUpdate: true,
        initialData: doctor,
        role: 'Bác sĩ',
        onSubmit: _onSubmit,
      ),
    );
  }
}