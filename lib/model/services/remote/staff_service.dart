import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pbl6mobile/shared/services/store.dart';

import 'auth_service.dart';

class StaffService {
  const StaffService._();
  static const StaffService instance = StaffService._();
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

  static Future<Map<String, dynamic>> getAdmins({String search = ''}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return {'success': false, 'data': []};
      }

      String url = '$_baseUrl/staffs?skip=0&limit=10&role=ADMIN';
      if (search.isNotEmpty) {
        url += '&search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (response.statusCode == 401) {
          final refreshSuccess = await AuthService.refreshToken();
          if (refreshSuccess) {
            final newAccessToken = await Store.getAccessToken();
            if (newAccessToken != null) {
              final retryResponse = await http.get(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newAccessToken',
                },
              ).timeout(const Duration(seconds: 10));
              if (retryResponse.statusCode == 200) {
                return jsonDecode(retryResponse.body);
              }
            }
          }
        }
        return {'success': false, 'data': []};
      }
    } catch (e) {
      print('Get admins error: $e');
      return {'success': false, 'data': []};
    }
  }

  static Future<Map<String, dynamic>> getDoctors({String search = ''}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return {'success': false, 'data': []};
      }

      String url = '$_baseUrl/staffs?skip=0&limit=10&role=DOCTOR';
      if (search.isNotEmpty) {
        url += '&search=$search';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if (response.statusCode == 401) {
          final refreshSuccess = await AuthService.refreshToken();
          if (refreshSuccess) {
            final newAccessToken = await Store.getAccessToken();
            if (newAccessToken != null) {
              final retryResponse = await http.get(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newAccessToken',
                },
              ).timeout(const Duration(seconds: 10));
              if (retryResponse.statusCode == 200) {
                return jsonDecode(retryResponse.body);
              }
            }
          }
        }
        return {'success': false, 'data': []};
      }
    } catch (e) {
      print('Get doctors error: $e');
      return {'success': false, 'data': []};
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
      if (accessToken == null) {
        return false;
      }
      final dateParts = dateOfBirth.split('/');
      final formattedDate = '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';

      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'dateOfBirth': formattedDate,
        'isMale': isMale.toString(),
        'role': 'ADMIN',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/staffs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return true;
      } else {
        if (response.statusCode == 401) {
          final refreshSuccess = await AuthService.refreshToken();
          if (refreshSuccess) {
            final newAccessToken = await Store.getAccessToken();
            if (newAccessToken != null) {
              final retryResponse = await http.post(
                Uri.parse('$_baseUrl/staffs'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newAccessToken',
                },
                body: jsonEncode(requestBody),
              ).timeout(const Duration(seconds: 10));
              if (retryResponse.statusCode == 201) {
                return true;
              }
            }
          }
        }
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Create admin error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            print('Create admin parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      print('Create admin error: $e');
      return false;
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
      if (accessToken == null) {
        return false;
      }
      final dateParts = dateOfBirth.split('/');
      final formattedDate = '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';

      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
        'fullName': fullName,
        'dateOfBirth': formattedDate,
        'isMale': isMale.toString(),
        'role': 'DOCTOR',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/staffs'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return true;
      } else {
        if (response.statusCode == 401) {
          final refreshSuccess = await AuthService.refreshToken();
          if (refreshSuccess) {
            final newAccessToken = await Store.getAccessToken();
            if (newAccessToken != null) {
              final retryResponse = await http.post(
                Uri.parse('$_baseUrl/staffs'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newAccessToken',
                },
                body: jsonEncode(requestBody),
              ).timeout(const Duration(seconds: 10));
              if (retryResponse.statusCode == 201) {
                return true;
              }
            }
          }
        }
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Create doctor error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            print('Create doctor parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      print('Create doctor error: $e');
      return false;
    }
  }

  static Future<bool> updateStaff(String id, {
    String? fullName,
    String? email,
    String? password,
    String? phone,
    String? dateOfBirth,
    bool? isMale,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = <String, dynamic>{};
      if (fullName != null && fullName.isNotEmpty) requestBody['fullName'] = fullName;
      if (email != null && email.isNotEmpty) requestBody['email'] = email;
      if (password != null && password.isNotEmpty) requestBody['password'] = password;
      if (phone != null && phone.isNotEmpty) requestBody['phone'] = phone;
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        final dateParts = dateOfBirth.split('/');
        final formattedDate = '${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}';
        requestBody['dateOfBirth'] = formattedDate;
      }
      if (isMale != null) requestBody['isMale'] = isMale.toString();

      if (requestBody.isEmpty) {
        print('No fields to update');
        return false;
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/staffs/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        if (response.statusCode == 401) {
          final refreshSuccess = await AuthService.refreshToken();
          if (refreshSuccess) {
            final newAccessToken = await Store.getAccessToken();
            if (newAccessToken != null) {
              final retryResponse = await http.patch(
                Uri.parse('$_baseUrl/staffs/$id'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newAccessToken',
                },
                body: jsonEncode(requestBody),
              ).timeout(const Duration(seconds: 10));
              if (retryResponse.statusCode == 200) {
                return true;
              }
            }
          }
        }
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Update staff error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            print('Update staff parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      print('Update staff error: $e');
      return false;
    }
  }

  static Future<bool> deleteStaff(String id, {required String password}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = {
        'password': password,
      };

      final response = await http.delete(
        Uri.parse('$_baseUrl/staffs/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        if (response.statusCode == 401) {
          final refreshSuccess = await AuthService.refreshToken();
          if (refreshSuccess) {
            final newAccessToken = await Store.getAccessToken();
            if (newAccessToken != null) {
              final retryResponse = await http.delete(
                Uri.parse('$_baseUrl/staffs/$id'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newAccessToken',
                },
                body: jsonEncode(requestBody),
              ).timeout(const Duration(seconds: 10));
              if (retryResponse.statusCode == 200 || retryResponse.statusCode == 204) {
                return true;
              }
            }
          }
        }
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Delete staff error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            print('Delete staff parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      print('Delete staff error: $e');
      return false;
    }
  }
}