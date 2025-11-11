import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/local/profile_cache_service.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/model/services/local/staff_database_helper.dart';

class StaffVm extends ChangeNotifier {
  List<Staff> _staffs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _isOffline = false;
  int _currentPage = 1;
  final int _limit = 10;
  Map<String, dynamic> _meta = {};
  String _role = 'ADMIN';

  String _searchQuery = '';
  bool? _isMale;
  String? _sortBy = 'createdAt';
  String? _sortOrder = 'desc';

  Staff? _selfProfile;
  bool _isLoadingSelfProfile = false;
  String? _selfProfileError;

  List<Staff> get staffs => _staffs;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isOffline => _isOffline;
  bool get hasNext => _meta['hasNext'] ?? false;

  bool? get isMale => _isMale;
  String? get sortBy => _sortBy;
  String? get sortOrder => _sortOrder;

  Staff? get selfProfile => _selfProfile;
  bool get isLoadingSelfProfile => _isLoadingSelfProfile;
  String? get selfProfileError => _selfProfileError;

  final StaffDatabaseHelper _dbHelper = StaffDatabaseHelper.instance;
  final ProfileCacheService _profileCache = ProfileCacheService.instance;

  StaffVm() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isConnected = results.any((result) =>
      result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile);
      if (isConnected && _isOffline) {
        _isOffline = false;
        fetchStaffs(forceRefresh: true);
        if (_selfProfile != null || _selfProfileError != null) {
          fetchSelfProfile();
        }
      }
    });
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    fetchStaffs(forceRefresh: true);
  }

  void updateGenderFilter(bool? gender) {
    _isMale = gender;
    fetchStaffs(forceRefresh: true);
  }

  void updateSortFilter({String? sortBy, String? sortOrder}) {
    _sortBy = sortBy ?? _sortBy;
    _sortOrder = sortOrder ?? _sortOrder;
    fetchStaffs(forceRefresh: true);
  }

  void resetFilters() {
    _searchQuery = '';
    _isMale = null;
    _sortBy = 'createdAt';
    _sortOrder = 'desc';
    fetchStaffs(forceRefresh: true);
  }

  Future<void> fetchStaffs({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _currentPage = 1;
      _meta = {};
      _isLoading = true;
    } else {
      if (_isLoading || _isLoadingMore || !hasNext && !_isOffline) return;
      _isLoadingMore = true;
    }
    _error = null;
    notifyListeners();

    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = !connectivityResult.contains(ConnectivityResult.none);
    _isOffline = !isConnected;

    if (!isConnected) {
      _error = 'Bạn đang offline. Dữ liệu có thể đã cũ.';
      final offlineStaffs = await _dbHelper.getStaffs(
        role: _role,
        search: _searchQuery,
        isMale: _isMale,
        page: _currentPage,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (forceRefresh) {
        _staffs = offlineStaffs;
      } else {
        _staffs.addAll(offlineStaffs);
      }
      if (_staffs.isEmpty && forceRefresh) {
        _error = 'Không có dữ liệu offline.';
      }

      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
      return;
    }

    try {
      final result = await StaffService.getAdmins(
        search: _searchQuery,
        page: _currentPage,
        limit: _limit,
        isMale: _isMale,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (result.success) {
        if (forceRefresh) {
          _staffs = result.data;
        } else {
          _staffs.addAll(result.data);
        }
        _meta = result.meta;
        _currentPage++;

        if (_staffs.isNotEmpty &&
            _currentPage == 2 &&
            _searchQuery.isEmpty &&
            _isMale == null) {
          await _dbHelper.clearStaffs(role: _role);
          await _dbHelper.insertStaffs(_staffs);
        }
      } else {
        _error = result.message;
        if (forceRefresh) {
          _staffs = await _dbHelper.getStaffs(
            role: _role,
            search: _searchQuery,
            isMale: _isMale,
            page: 1,
            limit: _limit,
            sortBy: _sortBy,
            sortOrder: _sortOrder,
          );
          if (_staffs.isEmpty) {
            _error = result.message + " Không có dữ liệu offline.";
          } else {
            _error = result.message + " Đang hiển thị dữ liệu offline.";
          }
        }
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      if (forceRefresh) {
        _staffs = await _dbHelper.getStaffs(
          role: _role,
          search: _searchQuery,
          isMale: _isMale,
          page: 1,
          limit: _limit,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
        if (_staffs.isEmpty) {
          _error = "Lỗi kết nối: $e. Không có dữ liệu offline.";
        } else {
          _error = "Lỗi kết nối: $e. Đang hiển thị dữ liệu offline.";
        }
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchSelfProfile() async {
    _isLoadingSelfProfile = true;
    _selfProfile = null;
    _selfProfileError = null;
    notifyListeners();

    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = !connectivityResult.contains(ConnectivityResult.none);
    _isOffline = !isConnected;

    try {
      if (isConnected) {
        final profile = await AuthService.getProfile();
        if (profile != null &&
            (profile.role == 'ADMIN' || profile.role == 'SUPERADMIN')) {
          _selfProfile = Staff.fromJson(profile.toJson());
          await _profileCache.saveProfile(profile.toJson());
        } else if (profile != null) {
          _selfProfileError = "Lỗi: Tài khoản không phải là Admin.";
        } else {
          _selfProfileError = "Không tải được thông tin cá nhân.";
        }
      } else {
        print("Đang offline, thử tải profile Admin/Superadmin từ cache...");
        final cachedProfileMap = await _profileCache.getProfile();
        if (cachedProfileMap != null) {
          final role = cachedProfileMap['role'] as String?;
          if (role == 'ADMIN' || role == 'SUPERADMIN') {
            _selfProfile = Staff.fromJson(cachedProfileMap);
            _selfProfileError =
            "Bạn đang offline. Đang hiển thị thông tin đã lưu.";
          } else {
            _selfProfileError = "Lỗi cache: Tài khoản không phải là Admin.";
          }
        } else {
          _selfProfileError = "Bạn đang offline và không có dữ liệu cache.";
        }
      }
    } catch (e) {
      _selfProfileError = "Lỗi khi tải thông tin cá nhân: $e";
      if (_selfProfile == null) {
        print("API lỗi, thử tải profile Admin/Superadmin từ cache...");
        final cachedProfileMap = await _profileCache.getProfile();
        if (cachedProfileMap != null) {
          final role = cachedProfileMap['role'] as String?;
          if (role == 'ADMIN' || role == 'SUPERADMIN') {
            _selfProfile = Staff.fromJson(cachedProfileMap);
            _selfProfileError = "Lỗi kết nối. Đang hiển thị thông tin đã lưu.";
          } else {
            _selfProfileError = "Lỗi cache: Tài khoản không phải là Admin.";
          }
        } else {
          _selfProfileError = "Lỗi kết nối và không có dữ liệu cache. $e";
        }
      }
    } finally {
      _isLoadingSelfProfile = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (hasNext && !_isLoading && !_isLoadingMore && !_isOffline) {
      await fetchStaffs();
    }
  }

  Future<bool> deleteStaff(String id, String password) async {
    _error = null;
    bool success = false;
    try {
      success = await StaffService.deleteStaff(id, password: password);
      if (success) {
        _staffs.removeWhere((staff) => staff.id == id);
        await _dbHelper.deleteStaff(id);
      } else {
        _error = "Xóa thất bại. Vui lòng kiểm tra lại mật khẩu.";
      }
    } catch (e) {
      _error = "Lỗi khi xóa: $e";
      success = false;
    }
    notifyListeners();
    return success;
  }
}