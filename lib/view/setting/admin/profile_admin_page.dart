import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/profile.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';

class ProfileAdminPage extends StatefulWidget {
  final Profile profile;

  const ProfileAdminPage({super.key, required this.profile});

  @override
  State<ProfileAdminPage> createState() => _ProfileAdminPageState();
}

class _ProfileAdminPageState extends State<ProfileAdminPage> {
  late Profile _currentProfile;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  Future<void> _reloadProfile() async {
    final updatedProfile = await AuthService.getProfile();
    if (updatedProfile != null && mounted) {
      setState(() {
        _currentProfile = updatedProfile;
      });
    }
  }

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
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: context.theme.white,
            ),
            onPressed: () async {
              final shouldReload = await Navigator.pushNamed(
                context,
                Routes.editProfile,
                arguments: _currentProfile,
              );
              if (shouldReload == true) {
                _reloadProfile();
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: context.theme.primary.withOpacity(0.1),
          child: Text(
            _currentProfile.fullName.isNotEmpty ? _currentProfile.fullName[0].toUpperCase() : 'A',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: context.theme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _currentProfile.fullName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: context.theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentProfile.email,
          style: TextStyle(
            fontSize: 16,
            color: context.theme.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.theme.card,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoItem(
              context,
              icon: Icons.badge_outlined,
              label: 'Vai trò',
              value: _currentProfile.role,
            ),
            _buildInfoItem(
              context,
              icon: Icons.transgender_outlined,
              label: 'Giới tính',
              value: _currentProfile.isMale != null
                  ? (_currentProfile.isMale! ? 'Nam' : 'Nữ')
                  : 'Chưa cập nhật',
            ),
            _buildInfoItem(
              context,
              icon: Icons.cake_outlined,
              label: 'Ngày sinh',
              value: _currentProfile.dateOfBirth?.toString().split(' ')[0] ??
                  'Chưa cập nhật',
            ),
            _buildInfoItem(
              context,
              icon: Icons.phone_outlined,
              label: 'Số điện thoại',
              value: _currentProfile.phone ?? 'Chưa cập nhật',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context,
      {required IconData icon,
        required String label,
        required String value,
        bool isLast = false}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: context.theme.primary, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.theme.mutedForeground,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.theme.textColor,
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 32),
      ],
    );
  }
}