import 'package:flutter/material.dart';

import 'package:page_transition/page_transition.dart';
import 'package:pbl6mobile/view/change_password/change_password.dart';
import 'package:pbl6mobile/view/main_page/doctor/main_page_doctor.dart';
import 'package:pbl6mobile/view/main_page/super_admin/main_page_super_admin.dart';
import 'package:pbl6mobile/view/setting/super_admin/setting_supperadmin_page.dart';

import '../../view/admin_management/create_admin_page.dart';
import '../../view/admin_management/list_admin_page.dart';
import '../../view/admin_management/update_admin_page.dart';
import '../../view/auth/login_page.dart';
import '../../view/setting/setting_page.dart';

class Routes {
  static const login = '/login';
  static const mainPageDoctor = '/mainPageDoctor';
  static const setting = '/setting';
  static const changePassword = '/changePassword';
  static const mainPageSuperAdmin = '/mainPageSuperAdmin';
  static const settingSuperAdmin = '/settingSuperAdmin';
  static const createAdmin = '/createAdmin';
  static const listAdmin = '/listAdmin';
  static const updateAdmin = '/updateAdmin';




  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const LoginPage(),
        );
        case mainPageDoctor:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const MainPageDoctor(),
        );
        case createAdmin:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const CreateAdminPage(),
        );
        case listAdmin:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const AdminListPage(),
        );
        case changePassword:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const ChangePasswordPage(),
        );
        case settingSuperAdmin:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const SettingSupperAdminPage(),
        );
      case mainPageSuperAdmin:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const MainPageSuperAdmin(),
        );
        case setting:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const SettingPage(),
        );
      case updateAdmin:
        final admin = settings.arguments as Map<String, dynamic>?;
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child:  UpdateAdminPage(admin: admin!,),
        );
      default:
        return MaterialPageRoute(
          builder: (context) =>
          const Scaffold(
            body: Center(child: Text('No page route provided')),
          ),
        );
    }
  }
}