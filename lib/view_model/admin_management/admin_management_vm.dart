import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
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

  List<Staff> get staffs => _staffs;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isOffline => _isOffline;
  bool get hasNext => _meta['hasNext'] ?? false;

  bool? get isMale => _isMale;
  String? get sortBy => _sortBy;
  String? get sortOrder => _sortOrder;

  final StaffDatabaseHelper _dbHelper = StaffDatabaseHelper.instance;

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
      _staffs.clear();
      _meta = {};
      _isLoading = true;
    } else {
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
      _staffs = offlineStaffs;
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

        if (_staffs.isNotEmpty && _currentPage == 1) {
          await _dbHelper.clearStaffs(role: _role);
          await _dbHelper.insertStaffs(_staffs);
        }
      } else {
        _error = result.message;
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (hasNext && !_isLoading && !_isLoadingMore && !_isOffline) {
      _currentPage++;
      await fetchStaffs();
    }
  }

  Future<bool> deleteStaff(String id, String password) async {
    final success = await StaffService.deleteStaff(id, password: password);
    if (success) {
      _staffs.removeWhere((staff) => staff.id == id);
      await _dbHelper.deleteStaff(id);
      notifyListeners();
    }
    return success;
  }
}