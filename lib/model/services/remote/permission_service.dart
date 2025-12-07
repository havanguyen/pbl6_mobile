import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/entities/my_permission.dart';
import 'package:pbl6mobile/model/entities/permission_stats.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';

class PermissionService {
  static Dio get _dio => AuthService.getSecureDioInstance();

  static Future<Map<String, dynamic>> getAllGroups() async {
    try {
      final response = await _dio.get('/permissions/groups');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final groups = data.map((e) => PermissionGroup.fromJson(e)).toList();
        return {'success': true, 'data': groups};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e is DioException
            ? e.response?.data['message'] ?? e.message
            : e.toString(),
      };
    }
  }

  static Future<bool> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        '/permissions/groups',
        data: {'name': name, 'description': description},
      );
      return response.statusCode == 201 && response.data['success'] == true;
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
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (isActive != null) data['isActive'] = isActive;

      final response = await _dio.put('/permissions/groups/$id', data: data);

      print(
        'PermissionService.updateGroup response: ${response.statusCode} ${response.data}',
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('PermissionService.updateGroup exception: $e');
      return false;
    }
  }

  static Future<bool> deleteGroup(String id) async {
    try {
      final response = await _dio.delete('/permissions/groups/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getGroupPermissions(
    String groupId,
  ) async {
    try {
      final response = await _dio.get(
        '/permissions/groups/$groupId/permissions',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final permissions = data.map((e) => Permission.fromJson(e)).toList();
        return {'success': true, 'data': permissions};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e is DioException
            ? e.response?.data['message'] ?? e.message
            : e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> getAllPermissions() async {
    try {
      final response = await _dio.get('/permissions');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        final permissions = data.map((e) => Permission.fromJson(e)).toList();
        return {'success': true, 'data': permissions};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e is DioException
            ? e.response?.data['message'] ?? e.message
            : e.toString(),
      };
    }
  }

  static Future<bool> assignPermissionsToGroup(
    String groupId,
    List<String> permissions,
  ) async {
    try {
      final responses = await Future.wait(
        permissions.map(
          (permissionId) => _dio.post(
            '/permissions/groups/$groupId/permissions',
            data: {'permissionId': permissionId},
          ),
        ),
      );

      return responses.every((response) {
        return response.statusCode == 201 && response.data['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<bool> revokePermissionsFromGroup(
    String groupId,
    List<String> permissions,
  ) async {
    try {
      final responses = await Future.wait(
        permissions.map(
          (permissionId) => _dio.delete(
            '/permissions/groups/$groupId/permissions',
            data: {'permissionId': permissionId},
          ),
        ),
      );

      return responses.every((response) {
        return response.statusCode == 200 && response.data['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<List<Permission>> getUserPermissions(String userId) async {
    try {
      final response = await _dio.get('/permissions/users/$userId');

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          final List<dynamic> data = response.data['data'];
          // API returns objects without IDs at this endpoint
          // We map them to Permission objects with empty IDs, creating a snapshot
          return data.map((json) => Permission.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('getUserPermissions error: $e');
      return [];
    }
  }

  static Future<bool> assignUserPermission(
    String userId,
    String permissionId, {
    String effect = 'ALLOW',
  }) async {
    try {
      final response = await _dio.post(
        '/permissions/users/assign',
        data: {
          'userId': userId,
          'permissionId': permissionId,
          'effect': effect,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('assignUserPermission error: $e');
      if (e is DioException) {
        print('Assign error response: ${e.response?.data}');
      }
      return false;
    }
  }

  static Future<bool> revokeUserPermission(
    String userId,
    String permissionId,
  ) async {
    try {
      final response = await _dio.delete(
        '/permissions/users/revoke',
        data: {'userId': userId, 'permissionId': permissionId},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('revokeUserPermission error: $e');
      if (e is DioException) {
        print('Revoke error response: ${e.response?.data}');
      }
      return false;
    }
  }

  static Future<bool> assignPermissionsToUser(
    String userId,
    List<String> permissions,
  ) async {
    try {
      final responses = await Future.wait(
        permissions.map(
          (permissionId) => _dio.post(
            '/permissions/users/$userId/permissions',
            data: {'permissionId': permissionId},
          ),
        ),
      );

      return responses.every((response) {
        return response.statusCode == 201 && response.data['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<bool> revokePermissionsFromUser(
    String userId,
    List<String> permissions,
  ) async {
    try {
      final responses = await Future.wait(
        permissions.map(
          (permissionId) => _dio.delete(
            '/permissions/users/$userId/permissions',
            data: {'permissionId': permissionId},
          ),
        ),
      );

      return responses.every((response) {
        return response.statusCode == 200 && response.data['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<List<PermissionGroup>> getUserGroups(String userId) async {
    try {
      final response = await _dio.get('/permissions/users/$userId/groups');

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          final List<dynamic> data = response.data['data'];
          return data
              .map(
                (json) => PermissionGroup(
                  id: json['groupId'] ?? '',
                  name: json['groupName'] ?? '',
                  description: json['groupDescription'] ?? '',
                  tenantId: json['tenantId'] ?? '',
                  isActive: true,
                  createdAt: json['createdAt'] ?? '',
                  updatedAt: '',
                ),
              )
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> assignGroupsToUser(
    String userId,
    List<String> groupIds,
  ) async {
    try {
      final responses = await Future.wait(
        groupIds.map(
          (groupId) => _dio.post(
            '/permissions/users/$userId/groups',
            data: {'groupId': groupId},
          ),
        ),
      );

      return responses.every((response) {
        return response.statusCode == 201 && response.data['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<bool> revokeGroupsFromUser(
    String userId,
    List<String> groupIds,
  ) async {
    try {
      final responses = await Future.wait(
        groupIds.map(
          (groupId) => _dio.delete(
            '/permissions/users/$userId/groups',
            data: {'groupId': groupId},
          ),
        ),
      );

      return responses.every((response) {
        return response.statusCode == 200 && response.data['success'] == true;
      });
    } catch (e) {
      return false;
    }
  }

  static Future<List<MyPermission>> getMyPermissions() async {
    try {
      final response = await _dio.get('/permissions/me');
      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          final List data = response.data['data'];
          return data.map((e) => MyPermission.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('getMyPermissions error: $e');
      return [];
    }
  }

  static Future<PermissionStats?> getPermissionStats() async {
    try {
      final response = await _dio.get('/permissions/stats');
      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return PermissionStats.fromJson(response.data['data']);
        }
      }
      return null;
    } catch (e) {
      print('getPermissionStats error: $e');
      return null;
    }
  }
}
