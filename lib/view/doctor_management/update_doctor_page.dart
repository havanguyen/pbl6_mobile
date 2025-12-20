import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

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

    // Check for changes
    final initialEmail = doctor['email'] as String? ?? '';
    final initialFullName = doctor['fullName'] as String? ?? '';
    final initialPhone = doctor['phone'] as String?;
    final initialIsMale = doctor['isMale'] as bool?;
    final initialDobRaw = doctor['dateOfBirth'] as String?;
    String initialDob = '';
    if (initialDobRaw != null) {
      // Assuming initialDob comes in YYYY-MM-DD or ISO format from backend/json
      // We should try to normalize it to simple YYYY-MM-DD for comparison if possible,
      // roughly matching _convertDateFormat's output.
      if (initialDobRaw.contains('T')) {
        initialDob = initialDobRaw.split('T')[0];
      } else {
        initialDob = initialDobRaw;
      }
    }

    final String? emailToSend = (email != initialEmail) ? email : null;
    final String? fullNameToSend = (fullName != initialFullName)
        ? fullName
        : null;
    final String? passwordToSend = (password.isNotEmpty)
        ? password
        : null; // Password always optional/change if present
    final String? phoneToSend = (phone != initialPhone) ? phone : null;
    final bool? isMaleToSend = (isMale != initialIsMale) ? isMale : null;
    final String? dobToSend = (convertedDate != initialDob)
        ? convertedDate
        : null;

    // If no changes, return true immediately or Handle as success
    if (emailToSend == null &&
        fullNameToSend == null &&
        passwordToSend == null &&
        phoneToSend == null &&
        isMaleToSend == null &&
        dobToSend == null) {
      return true;
    }

    final success = await DoctorService.updateDoctor(
      id!,
      fullName: fullNameToSend,
      email: emailToSend,
      password: passwordToSend,
      phone: phoneToSend,
      dateOfBirth: dobToSend,
      isMale: isMaleToSend,
    );

    return success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        title: Text(
          AppLocalizations.of(context).translate('update_doctor_account'),
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
        role: AppLocalizations.of(context).translate('doctor_role'),
        onSubmit: _onSubmit,
        onSuccess: () {
          Navigator.pop(context, true);
        },
      ),
    );
  }
}
