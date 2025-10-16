import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view/setting/admin/profile_admin_page.dart';

import '../../../shared/themes/cubit/theme_cubit.dart';
import '../../../shared/widgets/widget/logout_confirm_dialog.dart';


class SettingAdminPage extends StatelessWidget {
  const SettingAdminPage({super.key});

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
                    builder: (context) => ProfileAdminPage(profile: profile),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
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
              Icons.type_specimen_outlined,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Quản lý chuyên khoa',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.textColor,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, Routes.listSpecialty);
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: Icon(
              Icons.location_city_outlined,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Quản lý địa điểm khám',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.textColor,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, Routes.listLocationWork);
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: Icon(
              Icons.brightness_6_outlined,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Chủ đề (Theme)',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.textColor,
              ),
            ),
            trailing: DropdownButton<ThemeMode>(
              value: context
                  .read<ThemeCubit>()
                  .state
                  .themeMode,
              dropdownColor: context.theme.bg,
              focusColor: context.theme.grey,
              items: [
                DropdownMenuItem(value: ThemeMode.light,
                    child: Text('Light',
                        style: TextStyle(color: context.theme.textColor))),
                DropdownMenuItem(value: ThemeMode.dark,
                    child: Text('Dark',
                        style: TextStyle(color: context.theme.textColor))),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<ThemeCubit>().changeTheme(value);
                }
              },
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: context.theme.destructive,
              size: 28,
            ),
            title: Text(
              'Đăng xuất',
              style: TextStyle(
                fontSize: 16,
                color: context.theme.destructive,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const LogoutConfirmationDialog();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}