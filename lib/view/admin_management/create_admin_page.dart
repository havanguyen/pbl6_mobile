import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

import '../../shared/widgets/widget/staff_form.dart';

class CreateAdminPage extends StatelessWidget {
  const CreateAdminPage({super.key});

  String _convertDateFormat(String input) {
    print('🔄 Converting date format: $input');

    try {
      if (input.contains('/')) {
        final parts = input.split('/');
        if (parts.length != 3) {
          print('❌ Invalid dd/mm/yyyy format: $input');
          return input;
        }
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        final formattedDate = '$year-$month-$day';
        print('✅ Converted dd/mm/yyyy to ISO: $formattedDate');
        return formattedDate;
      } else if (input.contains('-')) {
        print('✅ Date is already in ISO format: $input');
        return input;
      } else {
        print('❌ Unknown date format: $input');
        return input;
      }
    } catch (e) {
      print('❌ Error in _convertDateFormat: $e');
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
    final success = await StaffService.createAdmin(
      email: email,
      password: password,
      fullName: fullName,
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
          AppLocalizations.of(context).translate('create_admin_account'),
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: context.theme.bg,
      body: StaffForm(
        isUpdate: false,
        initialData: null,
        role: 'Admin',
        onSubmit: _onSubmit,
        onSuccess: () {
          print('✅ Admin created successfully, will refresh list');
        },
      ),
    );
  }
}
