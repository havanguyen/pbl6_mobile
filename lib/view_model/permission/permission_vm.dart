import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/model/services/remote/permission_service.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';

class PermissionVm extends ChangeNotifier {
  List<PermissionGroup> _groups = [];
  List<PermissionGroup> get groups => _groups;

  List<Permission> _groupPermissions = [];
  List<Permission> get groupPermissions => _groupPermissions;

  List<Permission> _allPermissions = [];
  List<Permission> get allPermissions => _allPermissions;
  
  List<Permission> _currentUserPermissions = [];
  List<Permission> get currentUserPermissions => _currentUserPermissions;

  List<PermissionGroup> _currentUserGroups = [];
  List<PermissionGroup> get currentUserGroups => _currentUserGroups;
  
  List<Staff> _users = [];
  List<Staff> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await StaffService.getAdmins();
      if (result.success) {
        _users = result.data;
      } else {
        _error = result.message ?? 'Không thể tải danh sách người dùng';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getAllGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await PermissionService.getAllGroups();
      if (result['success'] == true) {
        _groups = result['data'];
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String name, String description) async {
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.createGroup(name: name, description: description);
    if (success) {
      await getAllGroups();
    } else {
      _error = 'Không thể tạo nhóm quyền';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateGroup(String id, String name, String description) async {
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.updateGroup(id: id, name: name, description: description);
    if (success) {
      await getAllGroups();
    } else {
      _error = 'Không thể cập nhật nhóm quyền';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteGroup(String id) async {
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.deleteGroup(id);
    if (success) {
      await getAllGroups();
    } else {
      _error = 'Không thể xóa nhóm quyền';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> fetchGroupPermissions(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await PermissionService.getGroupPermissions(groupId);
      if (result['success'] == true) {
        _groupPermissions = result['data'];
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPermissions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await PermissionService.getAllPermissions();
      if (result['success'] == true) {
        _allPermissions = result['data'];
      } else {
        _error = result['message'];
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignPermissions(String groupId, List<String> permissions) async {
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.assignPermissionsToGroup(groupId, permissions);
    if (success) {
      await fetchGroupPermissions(groupId);
    } else {
      _error = 'Không thể gán quyền';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> revokePermissions(String groupId, List<String> permissions) async {
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.revokePermissionsFromGroup(groupId, permissions);
    if (success) {
      await fetchGroupPermissions(groupId);
    } else {
      _error = 'Không thể thu hồi quyền';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  List<Permission> getPermissionsForGroup(String groupId) {
    // This logic might need to be adjusted if we want to cache permissions per group
    // For now, if _groupPermissions contains permissions for the requested group (which it should if fetchGroupPermissions was called), return it.
    // However, since we don't store a map of groupId -> permissions, we might rely on the fact that the UI calls fetchGroupPermissions before accessing this.
    // Ideally, we should check if the current _groupPermissions belong to the groupId, but we don't store that metadata.
    // Assuming the UI flow is correct:
    return _groupPermissions;
  }

  // User Permission Management
  Future<void> fetchUserPermissions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentUserPermissions = await PermissionService.getUserPermissions(userId);
    } catch (e) {
      _error = 'Lỗi tải quyền người dùng: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserGroups(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentUserGroups = await PermissionService.getUserGroups(userId);
    } catch (e) {
      _error = 'Lỗi tải nhóm quyền người dùng: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> assignUserPermissions(String userId, List<String> permissions) async {
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.assignPermissionsToUser(userId, permissions);
    if (success) {
      await fetchUserPermissions(userId);
    } else {
      _error = 'Không thể gán quyền cho người dùng';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> revokeUserPermissions(String userId, List<String> permissions) async {
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.revokePermissionsFromUser(userId, permissions);
    if (success) {
      await fetchUserPermissions(userId);
    } else {
      _error = 'Không thể thu hồi quyền của người dùng';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> assignUserGroups(String userId, List<String> groupIds) async {
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.assignGroupsToUser(userId, groupIds);
    if (success) {
      await fetchUserGroups(userId);
    } else {
      _error = 'Không thể gán nhóm cho người dùng';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> revokeUserGroups(String userId, List<String> groupIds) async {
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.revokeGroupsFromUser(userId, groupIds);
    if (success) {
      await fetchUserGroups(userId);
    } else {
      _error = 'Không thể thu hồi nhóm của người dùng';
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
