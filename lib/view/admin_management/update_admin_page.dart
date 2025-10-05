import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

import '../../shared/widgets/widget/staff_form.dart';

class UpdateAdminPage extends StatelessWidget {
  final Map<String, dynamic> admin;

  const UpdateAdminPage({super.key, required this.admin});

  String _convertDateFormat(String input) {
    print('🔄 Converting date format: $input');

    try {
      if (input.contains('/')) {
        // Định dạng dd/mm/yyyy -> chuyển sang yyyy-mm-dd
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
        // Đã là định dạng ISO, sử dụng trực tiếp
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
    final success = await StaffService.updateStaff(
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
          'Chỉnh sửa tài khoản admin',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: context.theme.bg,
      body: StaffForm(
        isUpdate: true,
        initialData: admin,
        role: 'Admin',
        onSubmit: _onSubmit,
        onSuccess: () {
          // Callback khi cập nhật thành công
          print('✅ Admin updated successfully, will refresh list');
        },
      ),
    );
  }
}