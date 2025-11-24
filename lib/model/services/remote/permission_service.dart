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
      print('Fetching all permissions from: $_baseUrl/permissions');
      final response = await http.get(
        Uri.parse('$_baseUrl/permissions'),
        headers: headers,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body['success'] == true) {
        final List<dynamic> data = body['data'];
        final permissions = data.map((e) => Permission.fromJson(e)).toList();
        return {'success': true, 'data': permissions};
      } else {
        return {'success': false, 'message': body['message'] ?? 'Unknown error'};
      }
    } catch (e) {
      print('Error fetching permissions: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<bool> assignPermissionsToGroup(String groupId, List<String> permissions) async {
    try {
      final headers = await _getHeaders();
      bool allSuccess = true;

      for (final permissionId in permissions) {
        print('Assigning permission $permissionId to group $groupId');
        final response = await http.post(
          Uri.parse('$_baseUrl/permissions/groups/$groupId/permissions'),
          headers: headers,
          body: jsonEncode({
            'permissionId': permissionId,
          }),
        );
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        final body = jsonDecode(response.body);
        if (response.statusCode != 201 || body['success'] != true) {
          allSuccess = false;
        }
      }
      return allSuccess;
    } catch (e) {
      print('Error assigning permissions: $e');
      return false;
    }
  }

  static Future<bool> revokePermissionsFromGroup(String groupId, List<String> permissions) async {
    try {
      final headers = await _getHeaders();
      bool allSuccess = true;

      for (final permissionId in permissions) {
        print('Revoking permission $permissionId from group $groupId');
        final response = await http.delete(
          Uri.parse('$_baseUrl/permissions/groups/$groupId/permissions'),
          headers: headers,
          body: jsonEncode({
            'permissionId': permissionId,
          }),
        );
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        final body = jsonDecode(response.body);
        if (response.statusCode != 200 || body['success'] != true) {
          allSuccess = false;
        }
      }
      return allSuccess;
    } catch (e) {
      print('Error revoking permissions: $e');
      return false;
    }
  }
}
