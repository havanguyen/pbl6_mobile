import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/shared/services/store.dart';

class PermissionService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await Store.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static String get _baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static Future<Map<String, dynamic>> getAllGroups() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/permissions/groups'),
        headers: headers,
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final List<dynamic> data = body['data'];
        final groups = data.map((e) => PermissionGroup.fromJson(e)).toList();
        return {'success': true, 'data': groups};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/permissions/groups'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
        }),
      );

      final body = jsonDecode(response.body);
      return response.statusCode == 201 && body['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateGroup({
    required String id,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (isActive != null) data['isActive'] = isActive;

      final response = await http.patch(
        Uri.parse('$_baseUrl/permissions/groups/$id'),
        headers: headers,
        body: jsonEncode(data),
      );

      final body = jsonDecode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteGroup(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/permissions/groups/$id'),
        headers: headers,
      );

      final body = jsonDecode(response.body);
      return response.statusCode == 200 && body['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getGroupPermissions(String groupId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/permissions/groups/$groupId/permissions'),
        headers: headers,
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final List<dynamic> data = body['data'];
        final permissions = data.map((e) => Permission.fromJson(e)).toList();
        return {'success': true, 'data': permissions};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAllPermissions() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/permissions'),
        headers: headers,
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final List<dynamic> data = body['data'];
        final permissions = data.map((e) => Permission.fromJson(e)).toList();
        return {'success': true, 'data': permissions};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Unknown error'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> assignPermissionsToGroup(String groupId, List<String> permissions) async {
    try {
      final headers = await _getHeaders();

      final responses = await Future.wait(
          permissions.map((permissionId) => http.post(
            Uri.parse('$_baseUrl/permissions/groups/$groupId/permissions'),
            headers: headers,
            body: jsonEncode({
              'permissionId': permissionId,
            }),
          ))
      );

      return responses.every((response) {
        final body = jsonDecode(response.body);
        return response.statusCode == 201 && body['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<bool> revokePermissionsFromGroup(String groupId, List<String> permissions) async {
    try {
      final headers = await _getHeaders();

      final responses = await Future.wait(
          permissions.map((permissionId) => http.delete(
            Uri.parse('$_baseUrl/permissions/groups/$groupId/permissions'),
            headers: headers,
            body: jsonEncode({
              'permissionId': permissionId,
            }),
          ))
      );

      return responses.every((response) {
        final body = jsonDecode(response.body);
        return response.statusCode == 200 && body['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<List<Permission>> getUserPermissions(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/permissions/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'];
          return data.map((json) => Permission.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> assignPermissionsToUser(String userId, List<String> permissions) async {
    try {
      final headers = await _getHeaders();

      final responses = await Future.wait(
          permissions.map((permissionId) => http.post(
            Uri.parse('$_baseUrl/permissions/users/$userId/permissions'),
            headers: headers,
            body: jsonEncode({
              'permissionId': permissionId,
            }),
          ))
      );

      return responses.every((response) {
        final body = jsonDecode(response.body);
        return response.statusCode == 201 && body['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<bool> revokePermissionsFromUser(String userId, List<String> permissions) async {
    try {
      final headers = await _getHeaders();

      final responses = await Future.wait(
          permissions.map((permissionId) => http.delete(
            Uri.parse('$_baseUrl/permissions/users/$userId/permissions'),
            headers: headers,
            body: jsonEncode({
              'permissionId': permissionId,
            }),
          ))
      );

      return responses.every((response) {
        final body = jsonDecode(response.body);
        return response.statusCode == 200 && body['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<List<PermissionGroup>> getUserGroups(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl/permissions/users/$userId/groups'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'];
          return data.map((json) => PermissionGroup(
            id: json['groupId'] ?? '',
            name: json['groupName'] ?? '',
            description: json['groupDescription'] ?? '',
            tenantId: json['tenantId'] ?? '',
            isActive: true,
            createdAt: json['createdAt'] ?? '',
            updatedAt: '',
          )).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> assignGroupsToUser(String userId, List<String> groupIds) async {
    try {
      final headers = await _getHeaders();

      final responses = await Future.wait(
          groupIds.map((groupId) => http.post(
            Uri.parse('$_baseUrl/permissions/users/$userId/groups'),
            headers: headers,
            body: jsonEncode({
              'groupId': groupId,
            }),
          ))
      );

      return responses.every((response) {
        final body = jsonDecode(response.body);
        return response.statusCode == 201 && body['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<bool> revokeGroupsFromUser(String userId, List<String> groupIds) async {
    try {
      final headers = await _getHeaders();

      final responses = await Future.wait(
          groupIds.map((groupId) => http.delete(
            Uri.parse('$_baseUrl/permissions/users/$userId/groups'),
            headers: headers,
            body: jsonEncode({
              'groupId': groupId,
            }),
          ))
      );

      return responses.every((response) {
        final body = jsonDecode(response.body);
        return response.statusCode == 200 && body['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }
}