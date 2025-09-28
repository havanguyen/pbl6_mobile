// lib/model/services/remote/specialty_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:retry/retry.dart';
import 'package:pbl6mobile/shared/services/store.dart';
import 'auth_service.dart';

class SpecialtyService {
  const SpecialtyService._();
  static const SpecialtyService instance = SpecialtyService._();
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];
  static final Logger _logger = Logger();

  static Future<http.Response> _retryHttp(Future<http.Response> Function() call) async {
    return retry(
      call,
      retryIf: (e) => e is SocketException || e is TimeoutException || e is http.ClientException,
      maxAttempts: 3,
      delayFactor: const Duration(seconds: 1),
    );
  }

  static Future<Map<String, dynamic>> getAllSpecialties({
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return {'success': false, 'data': []};
      }

      final url = '$_baseUrl/specialties?sortBy=$sortBy&sortOrder=$sortOrder&page=$page&limit=$limit';
      final response = await _retryHttp(() => http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10)));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await _retryHttp(() => http.get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newAccessToken',
              },
            ).timeout(const Duration(seconds: 10)));
            if (retryResponse.statusCode == 200) {
              return jsonDecode(retryResponse.body);
            }
          }
        }
        return {'success': false, 'data': []};
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            _logger.e('Get specialties error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            _logger.e('Get specialties parse error: $e');
          }
        }
        return {'success': false, 'data': []};
      }
    } catch (e) {
      _logger.e('Get specialties error: $e');
      return {'success': false, 'data': []};
    }
  }

  static Future<bool> createSpecialty({
    required String name,
    String? description,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = {'name': name};
      if (description != null && description.isNotEmpty) requestBody['description'] = description;

      final response = await _retryHttp(() => http.post(
        Uri.parse('$_baseUrl/specialties'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10)));

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await _retryHttp(() => http.post(
              Uri.parse('$_baseUrl/specialties'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newAccessToken',
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 10)));
            if (retryResponse.statusCode == 201) {
              return true;
            }
          }
        }
        return false;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            _logger.e('Create specialty error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            _logger.e('Create specialty parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      _logger.e('Create specialty error: $e');
      return false;
    }
  }

  static Future<bool> updateSpecialty({
    required String id,
    String? name,
    String? description,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = {};
      if (name != null && name.isNotEmpty) requestBody['name'] = name;
      if (description != null && description.isNotEmpty) requestBody['description'] = description;

      if (requestBody.isEmpty) {
        _logger.e('No fields to update');
        return false;
      }

      final response = await _retryHttp(() => http.patch(
        Uri.parse('$_baseUrl/specialties/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10)));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await _retryHttp(() => http.patch(
              Uri.parse('$_baseUrl/specialties/$id'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newAccessToken',
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 10)));
            if (retryResponse.statusCode == 200) {
              return true;
            }
          }
        }
        return false;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            _logger.e('Update specialty error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            _logger.e('Update specialty parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      _logger.e('Update specialty error: $e');
      return false;
    }
  }

  static Future<bool> deleteSpecialty(String id, {required String password}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = {'password': password};

      final response = await _retryHttp(() => http.delete(
        Uri.parse('$_baseUrl/specialties/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10)));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await _retryHttp(() => http.delete(
              Uri.parse('$_baseUrl/specialties/$id'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newAccessToken',
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 10)));
            if (retryResponse.statusCode == 200 || retryResponse.statusCode == 204) {
              return true;
            }
          }
        }
        return false;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            _logger.e('Delete specialty error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            _logger.e('Delete specialty parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      _logger.e('Delete specialty error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getInfoSections(String specialtyId) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return {'success': false, 'data': []};
      }

      final url = '$_baseUrl/specialties/$specialtyId/info-sections';
      final response = await _retryHttp(() => http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10)));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await _retryHttp(() => http.get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newAccessToken',
              },
            ).timeout(const Duration(seconds: 10)));
            if (retryResponse.statusCode == 200) {
              return jsonDecode(retryResponse.body);
            }
          }
        }
        return {'success': false, 'data': []};
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            _logger.e('Get info sections error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            _logger.e('Get info sections parse error: $e');
          }
        }
        return {'success': false, 'data': []};
      }
    } catch (e) {
      _logger.e('Get info sections error: $e');
      return {'success': false, 'data': []};
    }
  }

  static Future<bool> createInfoSection({
    required String specialtyId,
    required String name,
    required String content,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = {
        'specialtyId': specialtyId,
        'name': name,
        'content': content,
      };

      final response = await _retryHttp(() => http.post(
        Uri.parse('$_baseUrl/specialties/info-sections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10)));

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await _retryHttp(() => http.post(
              Uri.parse('$_baseUrl/specialties/info-sections'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newAccessToken',
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 10)));
            if (retryResponse.statusCode == 201) {
              return true;
            }
          }
        }
        return false;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            _logger.e('Create info section error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            _logger.e('Create info section parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      _logger.e('Create info section error: $e');
      return false;
    }
  }

  static Future<bool> updateInfoSection({
    required String id,
    String? name,
    String? content,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = {};
      if (name != null && name.isNotEmpty) requestBody['name'] = name;
      if (content != null && content.isNotEmpty) requestBody['content'] = content;

      if (requestBody.isEmpty) {
        _logger.e('No fields to update');
        return false;
      }

      final response = await _retryHttp(() => http.patch(
        Uri.parse('$_baseUrl/specialties/info-sections/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10)));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await _retryHttp(() => http.patch(
              Uri.parse('$_baseUrl/specialties/info-sections/$id'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newAccessToken',
              },
              body: jsonEncode(requestBody),
            ).timeout(const Duration(seconds: 10)));
            if (retryResponse.statusCode == 200) {
              return true;
            }
          }
        }
        return false;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            _logger.e('Update info section error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            _logger.e('Update info section parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      _logger.e('Update info section error: $e');
      return false;
    }
  }

  static Future<bool> deleteInfoSection(String id) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final response = await _retryHttp(() => http.delete(
        Uri.parse('$_baseUrl/specialties/info-section/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10)));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await _retryHttp(() => http.delete(
              Uri.parse('$_baseUrl/specialties/info-section/$id'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $newAccessToken',
              },
            ).timeout(const Duration(seconds: 10)));
            if (retryResponse.statusCode == 200 || retryResponse.statusCode == 204) {
              return true;
            }
          }
        }
        return false;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            _logger.e('Delete info section error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            _logger.e('Delete info section parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      _logger.e('Delete info section error: $e');
      return false;
    }
  }
}