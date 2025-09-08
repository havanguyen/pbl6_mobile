import 'package:flutter/material.dart';

import 'package:page_transition/page_transition.dart';
import 'package:pbl6mobile/view/main_page/main_page_doctor.dart';

import '../../view/auth/login_page.dart';

class Routes {
  static const login = '/login';
  static const mainPageDoctor = '/mainPageDoctor';


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