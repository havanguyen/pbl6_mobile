import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:pbl6mobile/firebase_options.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/themes/cubit/theme_cubit.dart';
import 'package:pbl6mobile/shared/themes/cubit/theme_state.dart';
import 'package:pbl6mobile/shared/themes/cubit/language_cubit.dart';
import 'package:pbl6mobile/shared/themes/cubit/language_state.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/shared/utils/global_keys.dart';
import 'package:pbl6mobile/view/splash/splash.dart';
import 'package:pbl6mobile/view_model/admin_management/admin_management_vm.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:pbl6mobile/view_model/appointment/appointment_vm.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/location_work_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/view_model/patient/patient_vm.dart';
import 'package:pbl6mobile/view_model/question/question_vm.dart';
import 'package:pbl6mobile/view_model/setting/office_hours_vm.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SnackbarService>(
          create: (_) => SnackbarService(),
        ),
        ChangeNotifierProvider<LocationWorkVm>(create: (_) => LocationWorkVm()),
        ChangeNotifierProvider<StaffVm>(create: (_) => StaffVm()),
        ChangeNotifierProvider<DoctorVm>(create: (_) => DoctorVm()),
        ChangeNotifierProvider<SpecialtyVm>(create: (_) => SpecialtyVm()),
        ChangeNotifierProvider<BlogVm>(create: (_) => BlogVm()),
        ChangeNotifierProvider<QuestionVm>(create: (_) => QuestionVm()),
        ChangeNotifierProvider<PatientVm>(create: (_) => PatientVm()),
        ChangeNotifierProvider<AppointmentVm>(create: (_) => AppointmentVm()),
        ChangeNotifierProvider<OfficeHoursVm>(create: (_) => OfficeHoursVm()),
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()..loadTheme()),
        BlocProvider<LanguageCubit>(
          create: (_) => LanguageCubit()..loadLanguage(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LanguageCubit, LanguageState>(
            builder: (context, languageState) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                title: 'Flutter App PBL6',
                debugShowCheckedModeBanner: false,
                themeMode: themeState.themeMode,
                theme: lightTheme,
                darkTheme: darkTheme,
                onGenerateRoute: Routes.onGenerateRoute,
                home: const SplashPage(),
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                  FlutterQuillLocalizations.delegate,
                ],
                supportedLocales: const [Locale('en'), Locale('vi')],
                locale: languageState.locale,
              );
            },
          );
        },
      ),
    );
  }
}
