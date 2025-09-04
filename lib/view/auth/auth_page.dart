import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_model/auth/auth_view_model.dart';
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    Provider.of<AuthViewModel>(context, listen: false).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}