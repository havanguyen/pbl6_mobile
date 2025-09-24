import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pbl6mobile/shared/services/store.dart';

import 'auth_service.dart';

class LocationWorkService {
  const LocationWorkService._();
  static const LocationWorkService instance = LocationWorkService._();
  static final String? _baseUrl = dotenv.env['API_BASE_URL'];

  static Future<Map<String, dynamic>> getAllLocations({String sortBy = 'createdAt', String sortOrder = 'ASC'}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return {'success': false, 'data': []};
      }

      final url = '$_baseUrl/work-locations/public?sortBy=$sortBy&sortOrder=$sortOrder';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
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
        return {'success': false, 'data': []};
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Get locations error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            print('Get locations parse error: $e');
          }
        }
        return {'success': false, 'data': []};
      }
    } catch (e) {
      print('Get locations error: $e');
      return {'success': false, 'data': []};
    }
  }
  static Future<Map<String, dynamic>> getLocationById(String id) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return {'success': false, 'data': null};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/work-locations/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await http.get(
              Uri.parse('$_baseUrl/work-locations/$id'),
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
        return {'success': false, 'data': null};
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Get location by ID error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            print('Get location by ID parse error: $e');
          }
        }
        return {'success': false, 'data': null};
      }
    } catch (e) {
      print('Get location by ID error: $e');
      return {'success': false, 'data': null};
    }
  }
  static Future<bool> createLocation({
    required String name,
    required String address,
    required String phone,
    required String timezone,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = {
        'name': name,
        'address': address,
        'phone': phone,
        'timezone': timezone,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/work-locations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await http.post(
              Uri.parse('$_baseUrl/work-locations'),
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
        return false;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Create location error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            print('Create location parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      print('Create location error: $e');
      return false;
    }
  }
  static Future<bool> updateLocation({
    required String id,
    String? name,
    String? address,
    String? phone,
    String? timezone,
  }) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = {};
      if (name != null && name.isNotEmpty) requestBody['name'] = name;
      if (address != null && address.isNotEmpty) requestBody['address'] = address;
      if (phone != null && phone.isNotEmpty) requestBody['phone'] = phone;
      if (timezone != null && timezone.isNotEmpty) requestBody['timezone'] = timezone;

      if (requestBody.isEmpty) {
        print('No fields to update');
        return false;
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/work-locations/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await http.patch(
              Uri.parse('$_baseUrl/work-locations/$id'),
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
        return false;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Update location error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            print('Update location parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      print('Update location error: $e');
      return false;
    }
  }
  static Future<bool> deleteLocation(String id, {required String password}) async {
    try {
      final String? accessToken = await Store.getAccessToken();
      if (accessToken == null) {
        return false;
      }

      final Map<String, dynamic> requestBody = {
        'password': password,
      };

      final response = await http.delete(
        Uri.parse('$_baseUrl/work-locations/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.refreshToken();
        if (refreshSuccess) {
          final newAccessToken = await Store.getAccessToken();
          if (newAccessToken != null) {
            final retryResponse = await http.delete(
              Uri.parse('$_baseUrl/work-locations/$id'),
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
        return false;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final Map<String, dynamic> errorData = jsonDecode(response.body);
            print('Delete location error: ${errorData['message'] ?? 'Unknown error'}');
          } catch (e) {
            print('Delete location parse error: $e');
          }
        }
        return false;
      }
    } catch (e) {
      print('Delete location error: $e');
      return false;
    }
  }
}