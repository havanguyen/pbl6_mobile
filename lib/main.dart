import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/themes/cubit/theme_cubit.dart';
import 'package:pbl6mobile/shared/themes/cubit/theme_state.dart';
import 'package:pbl6mobile/view/splash/splash.dart';
import 'package:pbl6mobile/view_model/admin_management/admin_management_vm.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/location_work_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SnackbarService>(create: (_) => SnackbarService()),
        ChangeNotifierProvider<LocationWorkVm>(create: (_) => LocationWorkVm()),
        ChangeNotifierProvider<StaffVm>(create: (_) => StaffVm()),
        ChangeNotifierProvider<DoctorVm>(create: (_) => DoctorVm()),
        ChangeNotifierProvider<SpecialtyVm>(create: (_) => SpecialtyVm()),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit()..loadTheme(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'Flutter App PBL6',
            debugShowCheckedModeBanner: false,
            themeMode: state.themeMode,
            theme: lightTheme,
            darkTheme: darkTheme,
            onGenerateRoute: Routes.onGenerateRoute,
            home: const SplashPage(),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('vi'),
            ],
          );
        },
      ),
    );
  }
}