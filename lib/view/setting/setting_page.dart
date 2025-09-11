import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view/setting/profile_page.dart';


class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Cài đặt',
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              Icons.person_outline,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Thông tin cá nhân',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.textColor,
              ),
            ),
            onTap: () async {
              final profile = await AuthService.getProfile();
              if (profile != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(profile: profile),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Không thể lấy thông tin cá nhân. Vui lòng thử lại.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Điều khoản sử dụng',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.textColor,
              ),
            ),
            onTap: () {
              print('Mở điều khoản sử dụng');
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: Icon(
              Icons.lightbulb_outline,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Hướng dẫn sử dụng',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.textColor,
              ),
            ),
            onTap: () {
              print('Mở hướng dẫn sử dụng');
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: Icon(
              Icons.shield_outlined,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Chính sách bảo mật',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.textColor,
              ),
            ),
            onTap: () {
              print('Mở chính sách bảo mật');
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.textColor,
              ),
            ),
            onTap: () async {
              bool success = await AuthService.logout();
              if (success && context.mounted) {
                Navigator.pushReplacementNamed(context, Routes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}