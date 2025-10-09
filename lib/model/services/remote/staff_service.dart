import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/shared/services/store.dart';

import '../../entities/admin_response.dart';
import 'auth_service.dart';

class StaffService {
  const StaffService._();
  static const StaffService instance = StaffService._();
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

  static Future<http.Response> _httpRetry(
      Future<http.Response> Function() request,
      {int maxRetries = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await request();

        if (response.statusCode == 429) {
          if (attempt >= maxRetries) {
            print('❌ All retry attempts failed for status 429.');
            return response;
          }
          attempt++;
          final delay = Duration(seconds: 1 << (attempt - 1));
          print('🚨 Received 429. Retrying in ${delay.inSeconds} seconds... (Attempt $attempt/$maxRetries)');
          await Future.delayed(delay);
          continue;
        }

        return response;

      } on SocketException catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          print('❌ Network error after $maxRetries attempts: $e');
          rethrow;
        }
        final delay = Duration(seconds: 1 << (attempt - 1));
        print('🚨 Network error. Retrying in ${delay.inSeconds} seconds... ($e)');
        await Future.delayed(delay);
      } on TimeoutException catch(e) {
        attempt++;
        if (attempt >= maxRetries) {
          print('❌ Timeout error after $maxRetries attempts: $e');
          rethrow;
        }
        final delay = Duration(seconds: 1 << (attempt-1));
        print('🚨 Request timed out. Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
      }
      catch (e) {
        print('💥 An unexpected error occurred during HTTP request: $e');
        rethrow;
      }
    }
  }

  static Future<GetAdminsResponse> getAdmins({
    String search = '',
    int page = 1,
    int limit = 10,
    bool? isMale,
    String? email,
    String? createdFrom,
    String? createdTo,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return GetAdminsResponse(success: false, message: 'No access token available');
      }

      String url = '$_baseUrl/staffs?page=$page&limit=$limit&role=ADMIN';
      if (search.isNotEmpty) url += '&search=$search';
      if (isMale != null) url += '&isMale=$isMale';
      if (email != null && email.isNotEmpty) url += '&email=$email';
      if (createdFrom != null && createdFrom.isNotEmpty) url += '&createdFrom=$createdFrom';
      if (createdTo != null && createdTo.isNotEmpty) url += '&createdTo=$createdTo';
      if (sortBy != null && sortBy.isNotEmpty) url += '&sortBy=$sortBy';
      if (sortOrder != null && sortOrder.isNotEmpty) url += '&sortOrder=$sortOrder';

      final response = await _httpRetry(() => http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 15)));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final staffList = (responseData['data'] as List)
            .map((json) => Staff.fromJson(json as Map<String, dynamic>))
            .toList();
        return GetAdminsResponse(
          success: true,
          data: staffList,
          meta: responseData['meta'] ?? {},
          message: responseData['message'] ?? 'Success',
        );
      } else if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          return getAdmins(
              search: search,
              page: page,
              limit: limit,
              isMale: isMale,
              email: email,
              createdFrom: createdFrom,
              createdTo: createdTo,
              sortBy: sortBy,
              sortOrder: sortOrder);
        }
      }
      return GetAdminsResponse(
          success: false, message: responseData['message'] ?? 'API call failed');
    } catch (e) {
      print('💥 Get admins error after retries: $e');
      return GetAdminsResponse(success: false, message: 'Network error or too many requests.');
    }
  }

  static Future<bool> createAdmin({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String dateOfBirth,
    required bool isMale,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;

      String formattedDate;
      if (dateOfBirth.contains('/')) {
        try {
          final dateParts = dateOfBirth.split('/');
          if (dateParts.length == 3) {
            final day = dateParts[0].padLeft(2, '0');
            final month = dateParts[1].padLeft(2, '0');
            final year = dateParts[2];
            formattedDate = '$year-$month-$day';
          } else {
            return false;
          }
        } catch (e) {
          return false;
        }
      } else if (dateOfBirth.contains('-')) {
        formattedDate = dateOfBirth;
      } else {
        return false;
      }

      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'dateOfBirth': formattedDate,
        'isMale': isMale.toString(),
        'role': 'ADMIN',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      final url = '$_baseUrl/staffs';
      final response = await _httpRetry(() => http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)));

      if (response.statusCode == 201) return true;

      if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          final newAccessToken = await Store.getAccessToken();
          final retryResponse = await _httpRetry(() => http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $newAccessToken'},
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 15)));
          return retryResponse.statusCode == 201;
        }
      }
      return false;
    } catch(e) {
      print('💥 Create admin error after retries: $e');
      return false;
    }
  }

  static Future<bool> updateStaff(
      String id, {
        String? fullName,
        String? email,
        String? password,
        String? phone,
        String? dateOfBirth,
        bool? isMale,
      }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;

      final Map<String, dynamic> requestBody = {};
      if (fullName != null && fullName.isNotEmpty) requestBody['fullName'] = fullName;
      if (email != null && email.isNotEmpty) requestBody['email'] = email;
      if (password != null && password.isNotEmpty) requestBody['password'] = password;
      if (phone != null && phone.isNotEmpty) requestBody['phone'] = phone;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        if (dateOfBirth.contains('/')) {
          try {
            final dateParts = dateOfBirth.split('/');
            if (dateParts.length == 3) {
              final day = dateParts[0].padLeft(2, '0');
              final month = dateParts[1].padLeft(2, '0');
              final year = dateParts[2];
              requestBody['dateOfBirth'] = '$year-$month-$day';
            }
          } catch (e) {
            requestBody['dateOfBirth'] = dateOfBirth;
          }
        } else {
          requestBody['dateOfBirth'] = dateOfBirth;
        }
      }
      if (isMale != null) requestBody['isMale'] = isMale.toString();


      if (requestBody.isEmpty) return false;

      final url = '$_baseUrl/staffs/$id';
      final response = await _httpRetry(() => http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)));

      if (response.statusCode == 200) return true;
      if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          final newAccessToken = await Store.getAccessToken();
          final retryResponse = await _httpRetry(() => http.patch(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $newAccessToken'},
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 15)));
          return retryResponse.statusCode == 200;
        }
      }
      return false;
    } catch (e) {
      print('💥 Update staff error after retries: $e');
      return false;
    }
  }

  static Future<bool> deleteStaff(String id, {required String password}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;

      if (!await AuthService.verifyPassword(password: password)) {
        return false;
      }

      final url = '$_baseUrl/staffs/$id';
      final response = await _httpRetry(() => http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 15)));

      if (response.statusCode == 200 || response.statusCode == 204) return true;
      if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          final newAccessToken = await Store.getAccessToken();
          final retryResponse = await _httpRetry(() => http.delete(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $newAccessToken'},
          ).timeout(const Duration(seconds: 15)));
          return retryResponse.statusCode == 200 || retryResponse.statusCode == 204;
        }
      }
      return false;
    } catch (e) {
      print('💥 Delete staff error after retries: $e');
      return false;
    }
  }
}