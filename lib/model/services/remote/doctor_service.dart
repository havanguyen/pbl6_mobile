import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/doctor_response.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/shared/services/store.dart';

class DoctorService {
  const DoctorService._();
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

  static Future<http.Response> _httpRetry(
      Future<http.Response> Function() request,
      {int maxRetries = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        final response = await request();
        if (response.statusCode == 429) {
          if (attempt >= maxRetries) return response;
          attempt++;
          final delay = Duration(seconds: 1 << (attempt - 1));
          await Future.delayed(delay);
          continue;
        }
        return response;
      } on SocketException {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        final delay = Duration(seconds: 1 << (attempt - 1));
        await Future.delayed(delay);
      } on TimeoutException {
        attempt++;
        if (attempt >= maxRetries) rethrow;
        final delay = Duration(seconds: 1 << (attempt - 1));
        await Future.delayed(delay);
      } catch (e) {
        rethrow;
      }
    }
  }

  static Future<GetDoctorsResponse> getDoctors({
    String search = '',
    int page = 1,
    int limit = 10,
    bool? isMale,
    String? createdFrom,
    String? createdTo,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return GetDoctorsResponse(
            success: false, message: 'No access token available');
      }

      String url = '$_baseUrl/doctors?page=$page&limit=$limit';
      if (search.isNotEmpty) url += '&search=$search';
      if (isMale != null) url += '&isMale=$isMale';
      if (createdFrom != null && createdFrom.isNotEmpty) {
        url += '&createdFrom=$createdFrom';
      }
      if (createdTo != null && createdTo.isNotEmpty) url += '&createdTo=$createdTo';
      if (sortBy != null && sortBy.isNotEmpty) url += '&sortBy=$sortBy';
      if (sortOrder != null && sortOrder.isNotEmpty) {
        url += '&sortOrder=$sortOrder';
      }

      final response = await _httpRetry(() => http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 15)));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final doctorList = (responseData['data'] as List)
            .map((json) => Doctor.fromJson(json as Map<String, dynamic>))
            .toList();
        return GetDoctorsResponse(
          success: true,
          data: doctorList,
          meta: responseData['meta'] ?? {},
          message: responseData['message'] ?? 'Success',
        );
      } else if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          return getDoctors(
            search: search,
            page: page,
            limit: limit,
            isMale: isMale,
            createdFrom: createdFrom,
            createdTo: createdTo,
            sortBy: sortBy,
            sortOrder: sortOrder,
          );
        }
      }
      return GetDoctorsResponse(
          success: false,
          message: responseData['message'] ?? 'API call failed');
    } catch (e) {
      return GetDoctorsResponse(
          success: false, message: 'Network error or too many requests.');
    }
  }

  static Future<bool> createDoctor({
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

      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth,
        'isMale': isMale.toString(),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      final url = '$_baseUrl/doctors';
      final response = await _httpRetry(() => http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)));

      if (response.statusCode == 201) return true;

      if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          final newAccessToken = await Store.getAccessToken();
          final retryResponse = await _httpRetry(() => http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newAccessToken'
            },
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 15)));
          return retryResponse.statusCode == 201;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateDoctor(
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
        requestBody['dateOfBirth'] = dateOfBirth;
      }
      if (isMale != null) requestBody['isMale'] = isMale.toString();

      if (requestBody.isEmpty) return false;

      final url = '$_baseUrl/doctors/$id';
      final response = await _httpRetry(() => http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)));

      if (response.statusCode == 200) return true;
      if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          final newAccessToken = await Store.getAccessToken();
          final retryResponse = await _httpRetry(() => http.patch(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newAccessToken'
            },
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 15)));
          return retryResponse.statusCode == 200;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteDoctor(String id, {required String password}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;

      if (!await AuthService.verifyPassword(password: password)) {
        return false;
      }

      final url = '$_baseUrl/doctors/$id';
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
          return retryResponse.statusCode == 200 ||
              retryResponse.statusCode == 204;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}