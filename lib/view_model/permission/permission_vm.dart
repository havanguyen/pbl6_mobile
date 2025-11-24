import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/doctor_response.dart'; // Đã thêm import này
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Gọi song song API lấy Admin và Doctor
      final results = await Future.wait([
        StaffService.getAdmins(),
        DoctorService.getDoctors(limit: 1000),
      ]);

      final List<Staff> mergedList = [];

      // 1. Xử lý kết quả Admin (StaffService)
      // Giả sử StaffService trả về một object có field success và data là List<Staff>
      final adminResult = results[0] as dynamic;
      if (adminResult.success == true) {
        final admins = adminResult.data as List<Staff>;
        mergedList.addAll(admins);
      }

      // 2. Xử lý kết quả Doctor (DoctorService)
      final doctorResult = results[1] as GetDoctorsResponse; // Đã fix lỗi type cast
      if (doctorResult.success) {
        final doctors = doctorResult.data;

        // Map Doctor -> Staff để chung định dạng
        final doctorStaffs = doctors.map((doc) {
          // Chuyển đổi ngày tháng an toàn
          DateTime? parseDate(dynamic date) {
            if (date is DateTime) return date;
            if (date is String) return DateTime.tryParse(date);
            return null;
          }

          return Staff(
            id: doc.id,
            email: doc.email,
            fullName: doc.fullName,
            role: 'Doctor', // Gán role để phân biệt trên UI
            phone: doc.phone, // Staff cho phép null
            isMale: doc.isMale,
            dateOfBirth: parseDate(doc.dateOfBirth),
            createdAt: parseDate(doc.createdAt),
            updatedAt: parseDate(doc.updatedAt),
            // Đã xóa avatar, address, isActive vì Staff không có các trường này
          );
        }).toList();

        mergedList.addAll(doctorStaffs);
      }

      // 3. Lọc trùng lặp dựa trên ID
      final ids = <String>{};
      final uniqueList = <Staff>[];
      for (var user in mergedList) {
        if (ids.add(user.id)) {
          uniqueList.add(user);
        }
      }

      _users = uniqueList;

    } catch (e) {
      _error = 'Lỗi tải danh sách người dùng: $e';
      print("Error fetching users: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- PERMISSION GROUP MANAGEMENT ---
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

  // --- PERMISSION DATA ---
  Future<void> fetchGroupPermissions(String groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await PermissionService.getGroupPermissions(groupId);
      if (result['success'] == true) {
        _groupPermissionsMap[groupId] = result['data'];
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
    if (_allPermissions.isNotEmpty) return;

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

  List<Permission> getPermissionsForGroup(String groupId) {
    return _groupPermissionsMap[groupId] ?? [];
  }

  // --- BATCH UPDATE PERMISSIONS (Group) ---
  Future<bool> updateGroupPermissionsList(String groupId, List<String> newPermissionIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentPermissions = _groupPermissionsMap[groupId] ?? [];
      final currentIds = currentPermissions.map((p) => p.id).toSet();
      final newIdsSet = newPermissionIds.toSet();

      final toAdd = newIdsSet.difference(currentIds).toList();
      final toRemove = currentIds.difference(newIdsSet).toList();

      bool successAdd = true;
      if (toAdd.isNotEmpty) {
        successAdd = await PermissionService.assignPermissionsToGroup(groupId, toAdd);
      }

      bool successRemove = true;
      if (toRemove.isNotEmpty) {
        successRemove = await PermissionService.revokePermissionsFromGroup(groupId, toRemove);
      }

      await fetchGroupPermissions(groupId);

      _isLoading = false;
      notifyListeners();
      return successAdd && successRemove;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- USER PERMISSION / GROUP ASSIGNMENT ---
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

  Future<bool> updateUserPermissionsList(String userId, List<String> newPermissionIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentIds = _currentUserPermissions.map((p) => p.id).toSet();
      final newIdsSet = newPermissionIds.toSet();

      final toAdd = newIdsSet.difference(currentIds).toList();
      final toRemove = currentIds.difference(newIdsSet).toList();

      bool successAdd = true;
      if (toAdd.isNotEmpty) {
        successAdd = await PermissionService.assignPermissionsToUser(userId, toAdd);
      }

      bool successRemove = true;
      if (toRemove.isNotEmpty) {
        successRemove = await PermissionService.revokePermissionsFromUser(userId, toRemove);
      }

      await fetchUserPermissions(userId);
      _isLoading = false;
      notifyListeners();
      return successAdd && successRemove;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUserGroupsList(String userId, List<String> newGroupIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentIds = _currentUserGroups.map((g) => g.id).toSet();
      final newIdsSet = newGroupIds.toSet();

      final toAdd = newIdsSet.difference(currentIds).toList();
      final toRemove = currentIds.difference(newIdsSet).toList();

      bool successAdd = true;
      if (toAdd.isNotEmpty) {
        successAdd = await PermissionService.assignGroupsToUser(userId, toAdd);
      }

      bool successRemove = true;
      if (toRemove.isNotEmpty) {
        successRemove = await PermissionService.revokeGroupsFromUser(userId, toRemove);
      }

      await fetchUserGroups(userId);
      _isLoading = false;
      notifyListeners();
      return successAdd && successRemove;
    } catch (e) {
      _error = e.toString();
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