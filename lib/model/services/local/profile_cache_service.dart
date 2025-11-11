import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class ProfileCacheService {
  final Logger _logger = Logger();
  static const String _profileCacheKey = 'user_self_profile_cache';

  ProfileCacheService._privateConstructor();
  static final ProfileCacheService instance =
  ProfileCacheService._privateConstructor();

  Future<void> saveProfile(Map<String, dynamic> profileJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileString = jsonEncode(profileJson);
      await prefs.setString(_profileCacheKey, profileString);
      _logger.i('Đã lưu self-profile vào cache.');
    } catch (e) {
      _logger.e('Lỗi khi lưu cache profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString(_profileCacheKey);
      if (profileString != null) {
        _logger.i('Đã đọc self-profile từ cache.');
        return jsonDecode(profileString) as Map<String, dynamic>;
      }
      _logger.w('Không tìm thấy self-profile trong cache.');
      return null;
    } catch (e) {
      _logger.e('Lỗi khi đọc cache profile: $e');
      return null;
    }
  }

  Future<void> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileCacheKey);
      _logger.i('Đã xóa cache self-profile.');
    } catch (e) {
      _logger.e('Lỗi khi xóa cache profile: $e');
    }
  }
}