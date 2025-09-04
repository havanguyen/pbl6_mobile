import 'package:shared_preferences/shared_preferences.dart';

class Store {
  const Store._();

  static const String _themeMode = 'theme_mode';
  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  static Future<void> setThemeMode(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeMode, value);
  }

  static Future<String> getThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_themeMode) ?? 'system';
  }
}