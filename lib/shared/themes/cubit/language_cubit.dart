import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl6mobile/shared/services/store.dart';
import 'language_state.dart';

class LanguageCubit extends Cubit<LanguageState> {
  LanguageCubit() : super(const LanguageState(locale: Locale('vi')));

  Future<void> loadLanguage() async {
    try {
      final languageCode = await Store.getLanguage();
      emit(LanguageState(locale: Locale(languageCode)));
    } catch (e) {
      debugPrint('Error loading language: $e');
      emit(const LanguageState(locale: Locale('vi')));
    }
  }

  Future<void> changeLanguage(Locale locale) async {
    try {
      await Store.setLanguage(locale.languageCode);
      emit(LanguageState(locale: locale));
    } catch (e) {
      debugPrint('Error changing language: $e');
    }
  }
}
