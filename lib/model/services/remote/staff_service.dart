import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pbl6mobile/shared/services/store.dart';

import 'auth_service.dart';

class StaffService {
  const StaffService._();
  static const StaffService instance = StaffService._();
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

  static Future<Map<String, dynamic>> getAdmins({
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
        print('❌ No access token available');
        return {'success': false, 'data': [], 'message': 'No access token'};
      }

      String url = '$_baseUrl/staffs?page=$page&limit=$limit&role=ADMIN';

      if (search.isNotEmpty) {
        url += '&search=$search';
      }
      if (isMale != null) {
        url += '&isMale=$isMale';
      }
      if (email != null && email.isNotEmpty) {
        url += '&email=$email';
      }
      if (createdFrom != null && createdFrom.isNotEmpty) {
        url += '&createdFrom=$createdFrom';
      }
      if (createdTo != null && createdTo.isNotEmpty) {
        url += '&createdTo=$createdTo';
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        url += '&sortBy=$sortBy';
      }
      if (sortOrder != null && sortOrder.isNotEmpty) {
        url += '&sortOrder=$sortOrder';
      }

      print('🔗 API URL: $url');
      print('🔑 Access Token: ${accessToken.substring(0, 20)}...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ API call successful');
        return responseData;
      } else {
        print('❌ API call failed with status: ${response.statusCode}');

        if (response.statusCode == 401) {
          print('🔄 Token expired, trying to refresh...');
          final refreshSuccess = await AuthService.refreshToken();
          if (refreshSuccess) {
            final newAccessToken = await Store.getAccessToken();
            if (newAccessToken != null) {
              print('🔄 Retrying with new token...');
              final retryResponse = await http.get(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newAccessToken',
                },
              ).timeout(const Duration(seconds: 10));

              if (retryResponse.statusCode == 200) {
                print('✅ Retry successful');
                return jsonDecode(retryResponse.body);
              } else {
                print('❌ Retry failed with status: ${retryResponse.statusCode}');
              }
            }
          }
        }

        // Trả về response body nếu có, để xem thông báo lỗi từ server
        if (response.body.isNotEmpty) {
          try {
            final errorData = jsonDecode(response.body);
            return {
              'success': false,
              'data': [],
              'message': errorData['message'] ?? 'API call failed'
            };
          } catch (e) {
            return {
              'success': false,
              'data': [],
              'message': response.body
            };
          }
        }

        return {
          'success': false,
          'data': [],
          'message': 'HTTP ${response.statusCode}'
        };
      }
    } catch (e) {
      print('💥 Get admins error: $e');
      return {
        'success': false,
        'data': [],
        'message': 'Network error: $e'
      };
    }
  }

  static Future<Map<String, dynamic>> getDoctors({
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
        return {'success': false, 'data': []};
      }

      String url = '$_baseUrl/staffs?page=$page&limit=$limit&role=DOCTOR&includeMetadata=true';

      if (search.isNotEmpty) {
        url += '&search=$search';
      }
      if (isMale != null) {
        url += '&isMale=$isMale';
      }
      if (email != null && email.isNotEmpty) {
        url += '&email=$email';
      }
      if (createdFrom != null && createdFrom.isNotEmpty) {
        url += '&createdFrom=$createdFrom';
      }
      if (createdTo != null && createdTo.isNotEmpty) {
        url += '&createdTo=$createdTo';
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        url += '&sortBy=$sortBy';
      }
      if (sortOrder != null && sortOrder.isNotEmpty) {
        url += '&sortOrder=$sortOrder';
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
        print('❌ No access token for create admin');
        return false;
      }

      // Debug các giá trị đầu vào
      print('🔄 Creating admin with:');
      print('   email: $email');
      print('   password: ${password != null ? "***" : "null"}');
      print('   fullName: $fullName');
      print('   phone: $phone');
      print('   dateOfBirth: $dateOfBirth');
      print('   isMale: $isMale');

      String formattedDate;

      // Kiểm tra định dạng date và xử lý linh hoạt
      if (dateOfBirth.contains('/')) {
        // Định dạng dd/mm/yyyy
        try {
          final dateParts = dateOfBirth.split('/');
          print('📅 Date parts (dd/mm/yyyy): $dateParts');

          if (dateParts.length == 3) {
            final day = dateParts[0].padLeft(2, '0');
            final month = dateParts[1].padLeft(2, '0');
            final year = dateParts[2];
            formattedDate = '$year-$month-$day';
            print('✅ Formatted date from dd/mm/yyyy: $formattedDate');
          } else {
            print('❌ Invalid dd/mm/yyyy format: $dateOfBirth');
            return false;
          }
        } catch (e) {
          print('❌ Error parsing dd/mm/yyyy date: $e');
          return false;
        }
      } else if (dateOfBirth.contains('-')) {
        // Định dạng ISO (yyyy-mm-dd) - sử dụng trực tiếp
        print('📅 Date is already in ISO format: $dateOfBirth');
        formattedDate = dateOfBirth;
      } else {
        // Định dạng không xác định
        print('❌ Unknown date format: $dateOfBirth');
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

      print('📦 Request body: $requestBody');

      final url = '$_baseUrl/staffs';
      print('🔗 POST URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 201) {
        print('✅ Admin created successfully');
        return true;
      } else {
        print('❌ Create admin failed with status: ${response.statusCode}');

        if (response.statusCode == 401) {
          print('🔄 Token expired, trying to refresh...');
          final refreshSuccess = await AuthService.refreshToken();
          if (refreshSuccess) {
            final newAccessToken = await Store.getAccessToken();
            if (newAccessToken != null) {
              print('🔄 Retrying with new token...');
              final retryResponse = await http.post(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newAccessToken',
                },
                body: jsonEncode(requestBody),
              ).timeout(const Duration(seconds: 10));

              if (retryResponse.statusCode == 201) {
                print('✅ Retry successful');
                return true;
              } else {
                print('❌ Retry failed with status: ${retryResponse.statusCode}');
              }
            }
          }
        }

        // Parse error message từ server
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            final errorMessage = errorData['message'] ?? 'Unknown error';
            print('❌ Create admin error: $errorMessage');
          } catch (e) {
            print('❌ Create admin parse error: $e');
            print('📋 Raw error response: ${response.body}');
          }
        }
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 Create admin error: $e');
      print('📋 Stack trace: $stackTrace');
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
        print('❌ No access token for update staff');
        return false;
      }

      final Map<String, dynamic> requestBody = <String, dynamic>{};

      // Debug các giá trị đầu vào
      print('🔄 Updating staff $id with:');
      print('   fullName: $fullName');
      print('   email: $email');
      print('   password: ${password != null ? "***" : "null"}');
      print('   phone: $phone');
      print('   dateOfBirth: $dateOfBirth');
      print('   isMale: $isMale');

      if (fullName != null && fullName.isNotEmpty) {
        requestBody['fullName'] = fullName;
      }
      if (email != null && email.isNotEmpty) {
        requestBody['email'] = email;
      }
      if (password != null && password.isNotEmpty) {
        requestBody['password'] = password;
      }
      if (phone != null && phone.isNotEmpty) {
        requestBody['phone'] = phone;
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        try {
          // Kiểm tra và xử lý dateOfBirth an toàn
          final dateParts = dateOfBirth.split('/');
          print('📅 Date parts: $dateParts');

          if (dateParts.length == 3) {
            final day = dateParts[0].padLeft(2, '0');
            final month = dateParts[1].padLeft(2, '0');
            final year = dateParts[2];
            final formattedDate = '$year-$month-$day';
            requestBody['dateOfBirth'] = formattedDate;
            print('✅ Formatted date: $formattedDate');
          } else {
            // Nếu không phải định dạng dd/mm/yyyy, sử dụng trực tiếp
            print('⚠️ Date format not dd/mm/yyyy, using as-is');
            requestBody['dateOfBirth'] = dateOfBirth;
          }
        } catch (e) {
          print('❌ Error formatting date: $e');
          // Vẫn gửi dateOfBirth gốc nếu có lỗi
          requestBody['dateOfBirth'] = dateOfBirth;
        }
      }
      if (isMale != null) {
        requestBody['isMale'] = isMale.toString();
      }

      print('📦 Request body: $requestBody');

      if (requestBody.isEmpty) {
        print('⚠️ No fields to update');
        return false;
      }

      final url = '$_baseUrl/staffs/$id';
      print('🔗 PATCH URL: $url');

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Staff updated successfully');
        return true;
      } else {
        print('❌ Update failed with status: ${response.statusCode}');

        if (response.statusCode == 401) {
          print('🔄 Token expired, trying to refresh...');
          final refreshSuccess = await AuthService.refreshToken();
          if (refreshSuccess) {
            final newAccessToken = await Store.getAccessToken();
            if (newAccessToken != null) {
              print('🔄 Retrying with new token...');
              final retryResponse = await http.patch(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $newAccessToken',
                },
                body: jsonEncode(requestBody),
              ).timeout(const Duration(seconds: 10));

              if (retryResponse.statusCode == 200) {
                print('✅ Retry successful');
                return true;
              } else {
                print('❌ Retry failed with status: ${retryResponse.statusCode}');
              }
            }
          }
        }

        // Parse error message từ server
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            final errorMessage = errorData['message'] ?? 'Unknown error';
            print('❌ Update staff error: $errorMessage');
          } catch (e) {
            print('❌ Update staff parse error: $e');
            print('📋 Raw error response: ${response.body}');
          }
        }
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 Update staff error: $e');
      print('📋 Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<bool> deleteStaff(String id, {required String password}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        print('No access token for delete staff');
        return false;
      }
      final bool isPasswordValid = await AuthService.verifyPassword(password: password);
      if (!isPasswordValid) {
        print('Password verification failed');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/staffs/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Staff deleted successfully');
        return true;
      } else if (response.statusCode == 401) {
        final bool refreshSuccess = await AuthService.refreshToken();
        if (!refreshSuccess) {
          print('Failed to refresh token for delete staff');
          return false;
        }

        final String? newAccessToken = await Store.getAccessToken();
        if (newAccessToken == null) {
          print('No new access token after refresh for delete staff');
          return false;
        }
        final bool retryPasswordValid = await AuthService.verifyPassword(password: password);
        if (!retryPasswordValid) {
          print('Password verification failed after refresh');
          return false;
        }

        final retryResponse = await http.delete(
          Uri.parse('$_baseUrl/staffs/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newAccessToken',
          },
        ).timeout(const Duration(seconds: 10));

        if (retryResponse.statusCode == 200 || retryResponse.statusCode == 204) {
          print('Staff deleted successfully after refresh');
          return true;
        } else {
          if (retryResponse.body.isNotEmpty) {
            try {
              final Map<String, dynamic> errorData = jsonDecode(retryResponse.body);
              print('Delete staff error after refresh: ${errorData['message'] ?? 'Unknown error'}');
            } catch (e) {
              print('Delete staff parse error after refresh: $e');
            }
          }
          return false;
        }
      } else {
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
      print('Delete staff network error: $e');
      return false;
    }
  }
}