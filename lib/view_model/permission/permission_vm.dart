import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor_response.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/model/services/remote/permission_service.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';

class PermissionVm extends ChangeNotifier {
  List<PermissionGroup> _groups = [];
  List<PermissionGroup> get groups => _groups;

  final Map<String, List<Permission>> _groupPermissionsMap = {};

  List<Permission> _allPermissions = [];
  List<Permission> get allPermissions => _allPermissions;

  List<Permission> _currentUserPermissions = [];
  List<Permission> get currentUserPermissions => _currentUserPermissions;

  List<PermissionGroup> _currentUserGroups = [];
  List<PermissionGroup> get currentUserGroups => _currentUserGroups;

  // Danh sách user bao gồm cả Admin, Doctor, SuperAdmin (được quy về Staff)
  List<Staff> _users = [];
  List<Staff> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // --- USER MANAGEMENT (Admin + Doctor + SuperAdmin) ---
  Future<void> fetchUsers() async {
    debugPrint("PermissionVm: fetchUsers() started");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        StaffService.getAdmins(),
        DoctorService.getDoctors(limit: 1000),
      ]);

      final List<Staff> mergedList = [];

      final adminResult = results[0] as dynamic;
      if (adminResult.success == true) {
        final admins = adminResult.data as List<Staff>;
        mergedList.addAll(admins);
      }

      final doctorResult = results[1] as GetDoctorsResponse;
      if (doctorResult.success) {
        final doctors = doctorResult.data;
        final doctorStaffs = doctors.map((doc) {
          DateTime? parseDate(dynamic date) {
            if (date is DateTime) return date;
            if (date is String) return DateTime.tryParse(date);
            return null;
          }

          return Staff(
            id: doc.id,
            email: doc.email,
            fullName: doc.fullName,
            role: 'Doctor',
            phone: doc.phone,
            isMale: doc.isMale,
            dateOfBirth: parseDate(doc.dateOfBirth),
            createdAt: parseDate(doc.createdAt),
            updatedAt: parseDate(doc.updatedAt),
          );
        }).toList();
        mergedList.addAll(doctorStaffs);
      }

      final ids = <String>{};
      final uniqueList = <Staff>[];
      for (var user in mergedList) {
        if (ids.add(user.id)) {
          uniqueList.add(user);
        }
      }

      _users = uniqueList;
      debugPrint("PermissionVm: fetchUsers() loaded ${_users.length} users");
    } catch (e) {
      _error = 'Lỗi tải danh sách người dùng: $e';
      debugPrint("PermissionVm: fetchUsers() error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- PERMISSION GROUP MANAGEMENT ---
  Future<void> getAllGroups() async {
    debugPrint("PermissionVm: getAllGroups() started");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await PermissionService.getAllGroups();
      if (result['success'] == true) {
        _groups = result['data'];
        debugPrint(
          "PermissionVm: getAllGroups() success, count: ${_groups.length}",
        );
      } else {
        _error = result['message'];
        debugPrint("PermissionVm: getAllGroups() failed: $_error");
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      debugPrint("PermissionVm: getAllGroups() exception: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup(String name, String description) async {
    debugPrint("PermissionVm: createGroup($name) started");
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.createGroup(
      name: name,
      description: description,
    );
    if (success) {
      await getAllGroups();
    } else {
      _error = 'Không thể tạo nhóm quyền';
      debugPrint("PermissionVm: createGroup() failed");
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateGroup(String id, String name, String description) async {
    debugPrint("PermissionVm: updateGroup($id, $name) started");
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.updateGroup(
      id: id,
      name: name,
      description: description,
    );
    if (success) {
      await getAllGroups();
    } else {
      _error = 'Không thể cập nhật nhóm quyền';
      debugPrint("PermissionVm: updateGroup() failed");
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteGroup(String id) async {
    debugPrint("PermissionVm: deleteGroup($id) started");
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.deleteGroup(id);
    if (success) {
      await getAllGroups();
    } else {
      _error = 'Không thể xóa nhóm quyền';
      debugPrint("PermissionVm: deleteGroup() failed");
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  // --- PERMISSION DATA ---
  Future<void> fetchGroupPermissions(String groupId) async {
    debugPrint("PermissionVm: fetchGroupPermissions($groupId) started");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await PermissionService.getGroupPermissions(groupId);
      if (result['success'] == true) {
        _groupPermissionsMap[groupId] = result['data'];
        debugPrint(
          "PermissionVm: fetchGroupPermissions success, count: ${result['data'].length}",
        );
      } else {
        _error = result['message'];
        debugPrint("PermissionVm: fetchGroupPermissions failed: $_error");
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      debugPrint("PermissionVm: fetchGroupPermissions exception: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllPermissions() async {
    debugPrint("PermissionVm: fetchAllPermissions() started");
    if (_allPermissions.isNotEmpty) {
      debugPrint("PermissionVm: allPermissions already loaded, skipping.");
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await PermissionService.getAllPermissions();
      if (result['success'] == true) {
        _allPermissions = result['data'];
        debugPrint(
          "PermissionVm: fetchAllPermissions success, count: ${_allPermissions.length}",
        );
      } else {
        _error = result['message'];
        debugPrint("PermissionVm: fetchAllPermissions failed: $_error");
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      debugPrint("PermissionVm: fetchAllPermissions exception: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Permission> getPermissionsForGroup(String groupId) {
    return _groupPermissionsMap[groupId] ?? [];
  }

  // --- BATCH UPDATE PERMISSIONS (Group) ---
  Future<bool> updateGroupPermissionsList(
    String groupId,
    List<String> newPermissionIds,
  ) async {
    debugPrint("PermissionVm: updateGroupPermissionsList($groupId) started");
    debugPrint(
      "PermissionVm: newPermissionIds count: ${newPermissionIds.length}",
    );
    _isLoading = true;
    notifyListeners();

    try {
      final currentPermissions = _groupPermissionsMap[groupId] ?? [];
      // Use permissionId for diffing, assuming newPermissionIds contains valid permission IDs
      final currentIds = currentPermissions
          .map((p) => p.permissionId.isNotEmpty ? p.permissionId : p.id)
          .toSet();
      final newIdsSet = newPermissionIds.toSet();

      final toAdd = newIdsSet.difference(currentIds).toList();
      final toRemove = currentIds.difference(newIdsSet).toList();

      debugPrint(
        "PermissionVm: toAdd: ${toAdd.length}, toRemove: ${toRemove.length}",
      );

      bool successAdd = true;
      if (toAdd.isNotEmpty) {
        successAdd = await PermissionService.assignPermissionsToGroup(
          groupId,
          toAdd,
        );
        debugPrint(
          "PermissionVm: assignPermissionsToGroup result: $successAdd",
        );
      }

      bool successRemove = true;
      if (toRemove.isNotEmpty) {
        successRemove = await PermissionService.revokePermissionsFromGroup(
          groupId,
          toRemove,
        );
        debugPrint(
          "PermissionVm: revokePermissionsFromGroup result: $successRemove",
        );
      }

      await fetchGroupPermissions(groupId);

      _isLoading = false;
      notifyListeners();
      return successAdd && successRemove;
    } catch (e) {
      _error = e.toString();
      debugPrint("PermissionVm: updateGroupPermissionsList exception: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- USER PERMISSION / GROUP ASSIGNMENT ---
  Future<void> fetchUserPermissions(String userId) async {
    debugPrint("PermissionVm: fetchUserPermissions($userId) started");
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentUserPermissions = await PermissionService.getUserPermissions(
        userId,
      );
      debugPrint(
        "PermissionVm: fetchUserPermissions success, count: ${_currentUserPermissions.length}",
      );
    } catch (e) {
      _error = 'Lỗi tải quyền người dùng: $e';
      debugPrint("PermissionVm: fetchUserPermissions exception: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserGroups(String userId) async {
    debugPrint("PermissionVm: fetchUserGroups($userId) started");
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentUserGroups = await PermissionService.getUserGroups(userId);
      debugPrint(
        "PermissionVm: fetchUserGroups success, count: ${_currentUserGroups.length}",
      );
    } catch (e) {
      _error = 'Lỗi tải nhóm quyền người dùng: $e';
      debugPrint("PermissionVm: fetchUserGroups exception: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper to map snapshot permissions (resource/action) to system IDs
  Set<String> getAssignedPermissionIdsForUser() {
    if (_allPermissions.isEmpty || _currentUserPermissions.isEmpty) {
      return {};
    }

    final assignedIds = <String>{};
    for (final userPerm in _currentUserPermissions) {
      // Find matching system permission by resource and action
      try {
        final systemPerm = _allPermissions.firstWhere(
          (p) =>
              p.resource.toLowerCase() == userPerm.resource.toLowerCase() &&
              p.action.toLowerCase() == userPerm.action.toLowerCase(),
        );

        final id = systemPerm.permissionId.isNotEmpty
            ? systemPerm.permissionId
            : systemPerm.id;
        assignedIds.add(id);
      } catch (_) {
        // No matching system permission found (maybe deprecated or custom)
      }
    }
    return assignedIds;
  }

  Future<bool> updateUserPermissionsList(
    String userId,
    List<String> newPermissionIds,
  ) async {
    debugPrint("PermissionVm: updateUserPermissionsList($userId) started");
    debugPrint(
      "PermissionVm: newPermissionIds count: ${newPermissionIds.length}",
    );
    _isLoading = true;
    notifyListeners();

    try {
      // Ensure all permissions are loaded to map IDs correctly
      if (_allPermissions.isEmpty) {
        await fetchAllPermissions();
      }

      final currentIds = getAssignedPermissionIdsForUser();
      final newIdsSet = newPermissionIds.toSet();

      final toAdd = newIdsSet.difference(currentIds).toList();
      final toRemove = currentIds.difference(newIdsSet).toList();
      debugPrint(
        "PermissionVm: toAdd: ${toAdd.length}, toRemove: ${toRemove.length}",
      );

      // Process additions
      bool successAdd = true;
      for (final id in toAdd) {
        final result = await PermissionService.assignUserPermission(userId, id);
        if (!result) successAdd = false;
        debugPrint("Assign permission $id result: $result");
      }

      // Process removals
      bool successRemove = true;
      for (final id in toRemove) {
        final result = await PermissionService.revokeUserPermission(userId, id);
        if (!result) successRemove = false;
        debugPrint("Revoke permission $id result: $result");
      }

      await fetchUserPermissions(userId);
      _isLoading = false;
      notifyListeners();
      return successAdd && successRemove;
    } catch (e) {
      _error = e.toString();
      debugPrint("PermissionVm: updateUserPermissionsList exception: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserGroupsList(
    String userId,
    List<String> newGroupIds,
  ) async {
    debugPrint("PermissionVm: updateUserGroupsList($userId) started");
    _isLoading = true;
    notifyListeners();

    try {
      final currentIds = _currentUserGroups.map((g) => g.id).toSet();
      final newIdsSet = newGroupIds.toSet();

      final toAdd = newIdsSet.difference(currentIds).toList();
      final toRemove = currentIds.difference(newIdsSet).toList();
      debugPrint(
        "PermissionVm: toAdd: ${toAdd.length}, toRemove: ${toRemove.length}",
      );

      bool successAdd = true;
      if (toAdd.isNotEmpty) {
        successAdd = await PermissionService.assignGroupsToUser(userId, toAdd);
        debugPrint("PermissionVm: assignGroupsToUser result: $successAdd");
      }

      bool successRemove = true;
      if (toRemove.isNotEmpty) {
        successRemove = await PermissionService.revokeGroupsFromUser(
          userId,
          toRemove,
        );
        debugPrint("PermissionVm: revokeGroupsFromUser result: $successRemove");
      }

      await fetchUserGroups(userId);
      _isLoading = false;
      notifyListeners();
      return successAdd && successRemove;
    } catch (e) {
      _error = e.toString();
      debugPrint("PermissionVm: updateUserGroupsList exception: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
