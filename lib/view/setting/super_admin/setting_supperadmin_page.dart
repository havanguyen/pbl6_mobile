import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view/setting/super_admin/profile_superadmin_page.dart';
import 'package:pbl6mobile/view/setting/office_hours/office_hours_page.dart';

import '../../../shared/themes/cubit/theme_cubit.dart';
import '../../../shared/widgets/widget/logout_confirm_dialog.dart';

class SettingSupperAdminPage extends StatelessWidget {
  const SettingSupperAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        elevation: 0.5,
        leading: IconButton(
          key: const ValueKey('settings_page_back_button'),
          icon: Icon(Icons.arrow_back, color: context.theme.white, size: 28),
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
            key: const ValueKey('settings_page_profile_button'),
            leading: Icon(
              Icons.person_outline,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Thông tin cá nhân',
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileSuperadminPage(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            key: const ValueKey('settings_page_permission_button'),
            leading: Icon(
              Icons.admin_panel_settings_outlined,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Quản lý phân quyền',
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            onTap: () {
              Navigator.pushNamed(context, Routes.permissionGroups);
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            key: const ValueKey('settings_page_specialty_button'),
            leading: Icon(
              Icons.type_specimen_outlined,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Quản lý chuyên khoa',
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            onTap: () {
              Navigator.pushNamed(context, Routes.listSpecialty);
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            key: const ValueKey('settings_page_location_button'),
            leading: Icon(
              Icons.location_city_outlined,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Quản lý địa điểm khám',
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            onTap: () {
              Navigator.pushNamed(context, Routes.listLocationWork);
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            key: const ValueKey('office_hours_management_menu_item'),
            leading: Icon(
              Icons.access_time,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Quản lý giờ làm việc',
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OfficeHoursPage(),
                ),
              );
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            key: const ValueKey('settings_page_patient_button'),
            leading: Icon(
              Icons.people_outline,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Quản lý bệnh nhân',
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            onTap: () {
              Navigator.pushNamed(context, Routes.listPatient);
            },
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            key: const ValueKey('settings_page_password_button'),
            leading: Icon(
              Icons.shield_outlined,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              'Đổi mật khẩu',
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            onTap: () {
              Navigator.pushNamed(context, Routes.changePassword);
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
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            trailing: DropdownButton<ThemeMode>(
              key: const ValueKey('settings_page_theme_dropdown'),
              value: context.read<ThemeCubit>().state.themeMode,
              dropdownColor: context.theme.bg,
              focusColor: context.theme.grey,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(
                    'Light',
                    style: TextStyle(color: context.theme.textColor),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(
                    'Dark',
                    style: TextStyle(color: context.theme.textColor),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(
                    'System',
                    style: TextStyle(color: context.theme.textColor),
                  ),
                ),
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
            key: const ValueKey('settings_page_logout_button'),
            leading: Icon(
              Icons.logout,
              color: context.theme.destructive,
              size: 28,
            ),
            title: Text(
              'Đăng xuất',
              style: TextStyle(fontSize: 16, color: context.theme.destructive),
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
