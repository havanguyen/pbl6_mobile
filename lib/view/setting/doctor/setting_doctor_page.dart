import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';

import '../../../shared/themes/cubit/theme_cubit.dart';
import '../../../shared/widgets/widget/logout_confirm_dialog.dart';
import '../../../shared/localization/app_localizations.dart';
import '../../../shared/widgets/language_switcher.dart';

class SettingDoctorPage extends StatelessWidget {
  const SettingDoctorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.blue,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white, size: 28),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          AppLocalizations.of(context).translate('settings'),
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
              Icons.account_circle_outlined,
              color: context.theme.blue,
              size: 28,
            ),
            title: Text(
              AppLocalizations.of(context).translate('account_management'),
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            onTap: () {
              Navigator.pushNamed(context, Routes.accountDoctor);
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
              AppLocalizations.of(context).translate('theme'),
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            trailing: DropdownButton<ThemeMode>(
              value: context.read<ThemeCubit>().state.themeMode,
              dropdownColor: context.theme.bg,
              focusColor: context.theme.grey,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(
                    AppLocalizations.of(context).translate('light_mode'),
                    style: TextStyle(color: context.theme.textColor),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(
                    AppLocalizations.of(context).translate('dark_mode'),
                    style: TextStyle(color: context.theme.textColor),
                  ),
                ),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(
                    AppLocalizations.of(context).translate('system_mode'),
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
            leading: Icon(Icons.language, color: context.theme.blue, size: 28),
            title: Text(
              AppLocalizations.of(context).translate('language'),
              style: TextStyle(fontSize: 16, color: context.theme.textColor),
            ),
            trailing: const LanguageSwitcher(),
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: context.theme.destructive,
              size: 28,
            ),
            title: Text(
              AppLocalizations.of(context).translate('logout'),
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
