import 'package:flutter/material.dart';

import '../../model/services/remote/auth_service.dart';
import '../../shared/routes/routes.dart';
import '../../shared/services/store.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    redirect();
  }

  @override
  Widget build(BuildContext context) {
    return  Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.blue.withOpacity(0.2), BlendMode.srcOver),
        ),
      ),
        child: Center(
          child: Image.asset(
              'assets/images/logo.png',
              color: Colors.blue,
              height: 200,
          ),
        ),
      );
  }

  Future<void> redirect() async {
    if((await AuthService.isLoggedIn()) == false) {
      await Store.clearStorage();
      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacementNamed(context, Routes.login);
    }
    else {
      String? role = await Store.getUserRole();
      if(role == 'SUPER_ADMIN') {
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, Routes.mainPageSuperAdmin);
      }
      else if(role == 'DOCTOR') {
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, Routes.mainPageDoctor);
      }
      else {
        await Store.clearStorage();
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pushReplacementNamed(context, Routes.login);
      }
    }
  }
}