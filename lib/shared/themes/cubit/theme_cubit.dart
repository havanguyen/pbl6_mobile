
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl6mobile/shared/themes/cubit/theme_state.dart';

import '../../services/store.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState());

  Future<void> loadTheme() async {
    try {
      final themeModeString = await Store.getThemeMode();
      final themeMode = _parseThemeMode(themeModeString);
      emit(ThemeState(themeMode: themeMode));
    } catch (e) {
      debugPrint('Error loading theme: $e');
      emit(const ThemeState(themeMode: ThemeMode.system));
    }
  }
  Future<void> changeTheme(ThemeMode themeMode) async {
    try {
      final themeModeString = _serializeThemeMode(themeMode);
      await Store.setThemeMode(themeModeString);
      emit(ThemeState(themeMode: themeMode));
    } catch (e) {
      debugPrint('Error changing theme: $e');
      emit(const ThemeState(themeMode: ThemeMode.system));
    }
  }

  ThemeMode _parseThemeMode(String? themeModeString) {
    switch (themeModeString) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }
  String _serializeThemeMode(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      default:
        return 'system';
    }
  }
}