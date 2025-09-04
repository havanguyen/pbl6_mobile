import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class Routes {
  static const String home = '/home';
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
    // case home:
    //      return PageTransition(
    //     type: PageTransitionType.rightToLeft,
    //     settings: settings,
    //     child: const MainPage(),
    //   );
      default:
        return MaterialPageRoute(
          builder: (context) => const Scaffold(
            body: Center(child: Text('No page route provided')),
          ),
        );
    }
  }
}