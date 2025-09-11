import 'package:flutter/material.dart';

import 'package:page_transition/page_transition.dart';
import 'package:pbl6mobile/view/change_password/change_password.dart';
import 'package:pbl6mobile/view/main_page/main_page_doctor.dart';

import '../../view/auth/login_page.dart';
import '../../view/setting/setting_page.dart';

class Routes {
  static const login = '/login';
  static const mainPageDoctor = '/mainPageDoctor';
  static const setting = '/setting';
  static const changePassword = '/changePassword';


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
        case changePassword:
        return PageTransition(
          type: PageTransitionType.fade,
          settings: settings,
          child: const ChangePasswordPage(),
        );
        case setting:
        return PageTransition(
          type: PageTransitionType.leftToRight,
          settings: settings,
          child: const SettingPage(),
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