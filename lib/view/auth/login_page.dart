import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/animation/scale_animation.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

import '../../model/services/remote/auth_service.dart';
import '../../shared/routes/routes.dart';
import '../../shared/services/store.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/widgets/language_switcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();

  String _email = '';
  String _password = '';
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _emailAnimation;
  late Animation<double> _passwordAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _footerAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _emailAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.5, curve: Curves.easeOut),
      ),
    );

    _passwordAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.7, 0.9, curve: Curves.easeOut),
      ),
    );

    _footerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.9, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      bool success = await AuthService.login(
        email: _email,
        password: _password,
      );

      if (success && mounted) {
        if ((await AuthService.isLoggedIn()) == false) {
          await Store.clearStorage();
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushReplacementNamed(context, Routes.login);
        } else {
          String? role = await Store.getUserRole();
          if (role == 'SUPER_ADMIN') {
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushReplacementNamed(context, Routes.mainPageSuperAdmin);
          } else if (role == 'ADMIN') {
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushReplacementNamed(context, Routes.mainPageAdmin);
          } else if (role == 'DOCTOR') {
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushReplacementNamed(context, Routes.mainPageDoctor);
          } else {
            await Store.clearStorage();
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushReplacementNamed(context, Routes.login);
          }
        }
      } else {
        _showErrorDialog(
          AppLocalizations.of(context).translate('login_failed'),
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('error')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('ok')),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _focusEmail.dispose();
    _focusPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: lightTheme,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                context.theme.blue.withOpacity(0.2),
                BlendMode.srcOver,
              ),
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40, right: 20),
                        child: const LanguageSwitcher(isCompact: true),
                      ),
                    ),
                    const Spacer(flex: 1),
                    AnimatedBuilder(
                      animation: _logoAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, 50 * (1 - _logoAnimation.value)),
                            child: child,
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/logo.png',
                        color: context.theme.blue,
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _emailAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _emailAnimation.value,
                          child: Transform.translate(
                            offset: Offset(
                              -50 * (1 - _emailAnimation.value),
                              0,
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: TextFormField(
                        key: const ValueKey('login_email_field'),
                        controller: _emailController,
                        focusNode: _focusEmail,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          ).translate('email'),
                          labelStyle: TextStyle(
                            color: context.theme.mutedForeground,
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: context.theme.primary,
                          ),
                          filled: true,
                          fillColor: context.theme.input,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.theme.border.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.theme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: TextStyle(color: context.theme.textColor),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _focusPassword.requestFocus();
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(
                              context,
                            ).translate('email_required');
                          }
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
                          );
                          if (!emailRegex.hasMatch(value)) {
                            return AppLocalizations.of(
                              context,
                            ).translate('email_invalid');
                          }
                          return null;
                        },
                        onSaved: (value) => _email = value!,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _passwordAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _passwordAnimation.value,
                          child: Transform.translate(
                            offset: Offset(
                              50 * (1 - _passwordAnimation.value),
                              0,
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: TextFormField(
                        key: const ValueKey('login_password_field'),
                        controller: _passwordController,
                        focusNode: _focusPassword,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          ).translate('password'),
                          labelStyle: TextStyle(
                            color: context.theme.mutedForeground,
                          ),
                          prefixIcon: Icon(
                            Icons.lock,
                            color: context.theme.primary,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: context.theme.mutedForeground,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                          filled: true,
                          fillColor: context.theme.input,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.theme.border.withOpacity(0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: context.theme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        style: TextStyle(color: context.theme.textColor),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(
                              context,
                            ).translate('password_required');
                          }
                          if (value.length < 8 ||
                              !value.contains(RegExp(r'[a-zA-Z]')) ||
                              !value.contains(RegExp(r'[0-9]'))) {
                            return AppLocalizations.of(
                              context,
                            ).translate('password_invalid');
                          }
                          return null;
                        },
                        onSaved: (value) => _password = value!,
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, Routes.forgotPassword),
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).translate('forgot_password'),
                          style: TextStyle(color: context.theme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _buttonAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _buttonAnimation.value,
                          child: Transform.scale(
                            scale: 0.5 + 0.5 * _buttonAnimation.value,
                            child: child,
                          ),
                        );
                      },
                      child: ScaleAnimatedButton(
                        child: CustomButtonBlue(
                          key: const ValueKey('login_button'),
                          onTap: _login,
                          text: _isLoading
                              ? '${AppLocalizations.of(context).translate('login_button')}...'
                              : AppLocalizations.of(
                                  context,
                                ).translate('login_button'),
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                    AnimatedBuilder(
                      animation: _footerAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _footerAnimation.value,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              30 * (1 - _footerAnimation.value),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        AppLocalizations.of(context).translate('app_slogan'),
                        style: TextStyle(
                          color: context.theme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
