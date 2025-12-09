import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/profile.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/shared/widgets/widget/staff_form.dart';

class EditProfilePage extends StatelessWidget {
  final Profile profile;

  const EditProfilePage({super.key, required this.profile});

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
    return await StaffService.updateStaff(
      id!,
      fullName: fullName,
      email: email,
      password: password.isEmpty ? null : password,
      phone: phone,
      dateOfBirth: convertedDate,
      isMale: isMale,
    );
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
          AppLocalizations.of(context).translate('edit_info_title'),
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      backgroundColor: context.theme.bg,
      body: StaffForm(
        isUpdate: true,
        initialData: initialData,
        role: profile.role,
        onSubmit: _onSubmit,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).translate('update_profile_succ'),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        },
      ),
    );
  }
}
