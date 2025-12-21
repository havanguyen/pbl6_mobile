import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/profile.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/doctor_form.dart';

class EditAccountDoctorPage extends StatelessWidget {
  final Profile profile;

  const EditAccountDoctorPage({super.key, required this.profile});

  String _convertDateFormat(String input) {
    try {
      if (input.contains('/')) {
        final parts = input.split('/');
        if (parts.length != 3) return input;
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
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

    final initialData = {
      'fullName': fullName,
      'phone': phone,
      'dateOfBirth': convertedDate,
      'isMale': isMale,
    };

    print('--- [DEBUG] EditAccountDoctorPage._onSubmit ---');
    print('Updating Profile for ID: $id');
    print('Data: $initialData');

    // Remove null or empty values
    final dataToSend = Map<String, dynamic>.from(initialData);
    dataToSend.removeWhere((key, value) => value == null || value == '');

    // Use AuthService.updateProfile which maps to PATCH /auth/profile
    return await AuthService.updateProfile(dataToSend);
  }

  @override
  Widget build(BuildContext context) {
    final initialData = {
      'id': profile.id,
      'email': profile.email,
      'fullName': profile.fullName,
      'phone': profile.phone,
      'dateOfBirth': profile.dateOfBirth?.toIso8601String(),
      'isMale': profile.isMale,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        title: Text(
          'Chỉnh sửa tài khoản',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      backgroundColor: context.theme.bg,
      body: DoctorForm(
        isUpdate: true,
        initialData: initialData,
        role: 'Bác sĩ',
        onSubmit: _onSubmit,
        onSuccess: () {
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
