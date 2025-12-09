import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor_response.dart';
import 'package:pbl6mobile/model/entities/permission.dart';
import 'package:pbl6mobile/model/entities/permission_group.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/model/services/remote/permission_service.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/model/entities/permission_stats.dart';

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

  PermissionStats? _stats;
  PermissionStats? get stats => _stats;

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
      _error = 'fetch_users_error'; // Key
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
        _error = 'fetch_groups_error';
        debugPrint("PermissionVm: getAllGroups() failed: ${result['message']}");
      }
    } catch (e) {
      _error = 'fetch_groups_error'; // Key
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
      _error = 'create_group_error'; // Key
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
    try {
      final result = await PermissionService.updateGroup(
        id: id,
        name: name,
        description: description,
      );

      if (result['success'] == true) {
        await getAllGroups();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final statusCode = result['statusCode'];
        final message = result['message']?.toString() ?? '';

        if (statusCode == 403 ||
            message.contains('Cannot rename default system group')) {
          _error = 'error_default_group_update';
        } else {
          _error = 'update_group_error';
        }
        debugPrint("PermissionVm: updateGroup() failed: $message");
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'update_group_error';
      debugPrint("PermissionVm: updateGroup() exception: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteGroup(String id) async {
    debugPrint("PermissionVm: deleteGroup($id) started");
    _isLoading = true;
    notifyListeners();
    final success = await PermissionService.deleteGroup(id);
    if (success) {
      await getAllGroups();
    } else {
      _error = 'delete_group_error'; // Key
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
        _error = 'fetch_permissions_error';
        debugPrint(
          "PermissionVm: fetchGroupPermissions failed: ${result['message']}",
        );
      }
    } catch (e) {
      _error = 'fetch_permissions_error'; // Key
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
        _error = 'fetch_permissions_error';
        debugPrint(
          "PermissionVm: fetchAllPermissions failed: ${result['message']}",
        );
      }
    } catch (e) {
      _error = 'fetch_permissions_error'; // Key
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
      _error = 'update_permissions_error'; // Key
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
      _error = 'fetch_permissions_error'; // Key
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
      _error = 'fetch_groups_error'; // Key
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
      _error = 'update_permissions_error'; // Key
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
      _error = 'update_group_error'; // Key - approximate match
      debugPrint("PermissionVm: updateUserGroupsList exception: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchStats() async {
    debugPrint("PermissionVm: fetchStats() started");
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stats = await PermissionService.getPermissionStats();
      debugPrint("PermissionVm: fetchStats success");
    } catch (e) {
      _error = 'fetch_stats_error'; // Key
      debugPrint("PermissionVm: fetchStats exception: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
