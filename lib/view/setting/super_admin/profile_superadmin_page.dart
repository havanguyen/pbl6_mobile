import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/profile.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';

class ProfileSuperadminPage extends StatelessWidget {
  final Profile profile;

  const ProfileSuperadminPage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.theme.white,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thông tin cá nhân',
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('Họ và tên', profile.fullName , context),
            _buildInfoItem('Email', profile.email , context),
            _buildInfoItem('Vai trò', profile.role , context),
            _buildInfoItem('Giới tính', profile.isMale != null ? (profile.isMale! ? 'Nam' : 'Nữ') : 'Chưa cập nhật' , context),
            _buildInfoItem(
                'Ngày sinh',
                profile.dateOfBirth?.toString().split(' ')[0] ?? 'Chưa cập nhật' , context
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value , BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:  TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style:  TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: context.theme.textColor,
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }
}