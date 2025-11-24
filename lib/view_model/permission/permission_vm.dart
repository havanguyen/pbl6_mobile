import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/model/services/remote/permission_service.dart';

class PermissionVm extends ChangeNotifier {
  List<PermissionGroup> _groups = [];
  List<PermissionGroup> get groups => _groups;

  List<Permission> _groupPermissions = [];
  List<Permission> get groupPermissions => _groupPermissions;

  List<Permission> getPermissionsForGroup(String groupId) {
    // Since we fetch permissions for a specific group and store them in _groupPermissions,
    // we can just return that list. The groupId argument is kept for compatibility 
    // with the UI call, but we assume the VM is properly initialized for the group.
    return _groupPermissions;
  }

  List<Permission> _allPermissions = [];
  List<Permission> get allPermissions => _allPermissions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchGroups() async {
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
      await fetchGroups();
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
      await fetchGroups();
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
      await fetchGroups();
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
  
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
