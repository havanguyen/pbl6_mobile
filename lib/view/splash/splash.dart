import 'package:flutter/material.dart';

import '../auth/auth_page.dart';

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A148C), Color(0xFF000000)],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/heart.png',
            width: MediaQuery.of(context).size.width*0.6,
          ),
        ),
      );
  }

  Future<void> redirect() async {
    await Future.delayed(const Duration(seconds: 2));
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (BuildContext context) => const AuthPage()));
  }
}