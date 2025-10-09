import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/specialty_response.dart';
import 'package:pbl6mobile/shared/services/store.dart';
import 'auth_service.dart';

class SpecialtyService {
  const SpecialtyService._();
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

  static Future<GetSpecialtiesResponse> getAllSpecialties({
    int page = 1,
    int limit = 10,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return GetSpecialtiesResponse(
            success: false, message: 'No access token available');
      }

      var uri = Uri.parse('$_baseUrl/specialties').replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (search != null && search.isNotEmpty) 'search': search,
      });

      final response = await _httpRetry(() => http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 15)));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final specialtyList = (responseData['data'] as List)
            .map((json) => Specialty.fromJson(json as Map<String, dynamic>))
            .toList();
        return GetSpecialtiesResponse(
          success: true,
          data: specialtyList,
          meta: responseData['meta'] ?? {},
          message: responseData['message'] ?? 'Success',
        );
      } else if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          return getAllSpecialties(
              page: page,
              limit: limit,
              search: search,
              sortBy: sortBy,
              sortOrder: sortOrder);
        }
      }
      return GetSpecialtiesResponse(
          success: false,
          message: responseData['message'] ?? 'API call failed');
    } catch (e) {
      return GetSpecialtiesResponse(
          success: false, message: 'Network error or too many requests.');
    }
  }

  static Future<bool> createSpecialty(
      {required String name, String? description}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;

      final Map<String, dynamic> requestBody = {'name': name};
      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      }

      final url = '$_baseUrl/specialties';
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

  static Future<bool> updateSpecialty(
      {required String id, String? name, String? description}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;

      final Map<String, dynamic> requestBody = {};
      if (name != null && name.isNotEmpty) requestBody['name'] = name;
      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      }

      if (requestBody.isEmpty) return false;

      final url = '$_baseUrl/specialties/$id';
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

  static Future<bool> deleteSpecialty(String id,
      {required String password}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;
      if (!await AuthService.verifyPassword(password: password)) {
        return false;
      }

      final url = '$_baseUrl/specialties/$id';
      final response = await _httpRetry(() => http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
      ).timeout(const Duration(seconds: 15)));

      if (response.statusCode == 200 || response.statusCode == 204) return true;

      if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          final newAccessToken = await Store.getAccessToken();
          final retryResponse = await _httpRetry(() => http.delete(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newAccessToken'
            },
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

  static Future<Map<String, dynamic>> getInfoSections(
      String specialtyId) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return {'success': false, 'data': []};

      final url = '$_baseUrl/specialties/$specialtyId/info-sections';
      final response = await _httpRetry(() => http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 15)));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        if (await AuthService.refreshToken()) {
          return getInfoSections(specialtyId);
        }
      }
      return {'success': false, 'data': []};
    } catch (e) {
      return {'success': false, 'data': []};
    }
  }

  static Future<bool> createInfoSection(
      {required String specialtyId,
        required String name,
        required String content}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;

      final Map<String, dynamic> requestBody = {
        'specialtyId': specialtyId,
        'name': name,
        'content': content,
      };

      final url = '$_baseUrl/specialties/info-sections';
      final response = await _httpRetry(() => http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)));

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateInfoSection(
      {required String id, String? name, String? content}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;

      final Map<String, dynamic> requestBody = {};
      if (name != null && name.isNotEmpty) requestBody['name'] = name;
      if (content != null && content.isNotEmpty) requestBody['content'] = content;

      if (requestBody.isEmpty) return false;

      final url = '$_baseUrl/specialties/info-sections/$id';
      final response = await _httpRetry(() => http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15)));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteInfoSection(String id, {required String password}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) return false;

      if (!await AuthService.verifyPassword(password: password)) {
        return false;
      }

      final url = '$_baseUrl/specialties/info-section/$id';
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