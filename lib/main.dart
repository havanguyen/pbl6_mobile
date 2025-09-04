
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/themes/cubit/theme_cubit.dart';
import 'package:pbl6mobile/shared/themes/cubit/theme_state.dart';
import 'package:pbl6mobile/view/splash/splash.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App PBL6',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const PBL6(),
    );
  }
}

class PBL6 extends StatefulWidget {
  const PBL6({super.key});

  @override
  State<PBL6> createState() => _PBL6State();
}

class _PBL6State extends State<PBL6> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => ThemeCubit()..loadTheme())],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: lightTheme,
            onGenerateRoute: Routes.onGenerateRoute,
            darkTheme: darkTheme,
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}