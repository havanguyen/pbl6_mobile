import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Store {
  const Store._();

  static const String _themeMode = 'theme_mode';

  static const _storage = FlutterSecureStorage();

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

  static Future<void> clearStorage() async {
    await _storage.deleteAll();
  }

  static Future<void> setAccessToken(String value) async {
    await _storage.write(key: 'access_token', value: value);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<void> setRefreshToken(String value) async {
    await _storage.write(key: 'refresh_token', value: value);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<void> setUserRole(String value) async {
    await _storage.write(key: 'user_role', value: value);
  }

  static Future<String?> getUserRole() async {
    return await _storage.read(key: 'user_role');
  }
}