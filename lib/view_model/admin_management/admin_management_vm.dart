import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/model/services/local/staff_database_helper.dart';

class StaffVm extends ChangeNotifier {
  List<Staff> _staffs = [];
  bool _isLoading = false;
  String? _error;
  bool _isOffline = false;
  int _currentPage = 1;
  int _limit = 10;
  Map<String, dynamic> _meta = {};
  String _role = 'ADMIN';

  String _searchQuery = '';
  bool? _isMale;
  String? _email;
  String? _createdFrom;
  String? _createdTo;
  String? _sortBy;
  String? _sortOrder;
  List<Staff> get staffs => _staffs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _isOffline;
  int get currentPage => _currentPage;
  int get total => _meta['total'] ?? 0;
  int get totalPages => _meta['totalPages'] ?? 1;
  bool get hasNext => _meta['hasNext'] ?? false;
  bool get hasPrev => _meta['hasPrev'] ?? false;
  String get role => _role;
  String get searchQuery => _searchQuery;
  bool? get isMale => _isMale;
  String? get email => _email;
  String? get createdFrom => _createdFrom;
  String? get createdTo => _createdTo;
  String? get sortBy => _sortBy;
  String? get sortOrder => _sortOrder;

  final StaffDatabaseHelper _dbHelper = StaffDatabaseHelper.instance;

  AdminManagementViewModel() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool isConnected = results.any((result) =>
      result == ConnectivityResult.wifi || result == ConnectivityResult.mobile);
      if (isConnected) {
        print('Network restored, syncing data...');
        syncStaffs();
      }
    });
  }

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void updateFilters({
    String? searchQuery,
    bool? isMale,
    String? email,
    String? createdFrom,
    String? createdTo,
    String? sortBy,
    String? sortOrder,
  }) {
    _searchQuery = searchQuery ?? _searchQuery;
    _isMale = isMale;
    _email = email;
    _createdFrom = createdFrom;
    _createdTo = createdTo;
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    fetchStaffs();
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _isMale = null;
    _email = null;
    _createdFrom = null;
    _createdTo = null;
    _sortBy = null;
    _sortOrder = null;
    fetchStaffs();
    notifyListeners();
  }

  Future<void> fetchStaffs({int? page, bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final targetPage = page ?? _currentPage;
    List<Staff> offlineStaffs = [];

    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      bool isConnected = connectivityResult.any((result) =>
      result == ConnectivityResult.wifi || result == ConnectivityResult.mobile);
      if (!forceRefresh || !isConnected) {
        offlineStaffs = await _dbHelper.getStaffs(
          search: _searchQuery,
          isMale: _isMale,
          email: _email,
          createdFrom: _createdFrom,
          createdTo: _createdTo,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          page: targetPage,
          limit: _limit,
        );
        if (offlineStaffs.isNotEmpty) {
          _staffs = offlineStaffs;
          _meta = {
            'total': offlineStaffs.length,
            'page': targetPage,
            'totalPages': (offlineStaffs.length / _limit).ceil(),
            'hasNext': offlineStaffs.length == _limit,
            'hasPrev': targetPage > 1,
          };
          notifyListeners();
        }
      }

      if (!isConnected && offlineStaffs.isNotEmpty) {
        print('No network, using local data');
        _isOffline = true;
        _error = 'Đang sử dụng dữ liệu offline';
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (!isConnected && offlineStaffs.isEmpty) {
        _isOffline = true;
        _error = 'Không có kết nối mạng và không có dữ liệu offline';
        _isLoading = false;
        notifyListeners();
        return;
      }

      print('Fetching ${_role.toLowerCase()}s from API...');
      final result = _role == 'ADMIN'
          ? await StaffService.getAdmins(
        search: _searchQuery,
        page: targetPage,
        limit: _limit,
        isMale: _isMale,
        email: _email,
        createdFrom: _createdFrom,
        createdTo: _createdTo,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      )
          : await StaffService.getDoctors(
        search: _searchQuery,
        page: targetPage,
        limit: _limit,
        isMale: _isMale,
        email: _email,
        createdFrom: _createdFrom,
        createdTo: _createdTo,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (result['success'] == true) {
        print('API call successful, processing data...');
        final data = result['data'] as List<dynamic>;
        print('Received ${data.length} ${_role.toLowerCase()}s from API');

        _staffs = data.map((json) {
          try {
            return Staff.fromJson(json);
          } catch (e) {
            print('Error parsing staff from JSON: $e');
            print('Problematic JSON: $json');
            return null;
          }
        }).where((staff) => staff != null).cast<Staff>().toList();

        _meta = result['meta'] ?? {};
        _currentPage = _meta['page'] ?? 1;
        _isOffline = false;
        _error = null;

        if (_staffs.isNotEmpty) {
          await _dbHelper.clearStaffs();
          await _dbHelper.insertStaffs(_staffs);
          print('Saved ${_staffs.length} ${_role.toLowerCase()}s to database');
        }
      } else {
        final apiError = result['message'] ?? 'Failed to load ${_role.toLowerCase()}s from API';
        print('API error: $apiError');
        if (offlineStaffs.isNotEmpty) {
          print('Loaded ${offlineStaffs.length} ${_role.toLowerCase()}s from database');
          _staffs = offlineStaffs;
          _isOffline = true;
          _error = 'Đang sử dụng dữ liệu offline';
          _meta = {
            'total': offlineStaffs.length,
            'page': targetPage,
            'totalPages': (offlineStaffs.length / _limit).ceil(),
            'hasNext': offlineStaffs.length == _limit,
            'hasPrev': targetPage > 1,
          };
        } else {
          _error = apiError;
          _isOffline = false;
        }
      }
    } catch (e) {
      print('Network error: $e');
      if (offlineStaffs.isNotEmpty) {
        print('Network error, loaded ${offlineStaffs.length} ${_role.toLowerCase()}s from database');
        _staffs = offlineStaffs;
        _isOffline = true;
        _error = 'Mất kết nối. Đang sử dụng dữ liệu offline';
        _meta = {
          'total': offlineStaffs.length,
          'page': targetPage,
          'totalPages': (offlineStaffs.length / _limit).ceil(),
          'hasNext': offlineStaffs.length == _limit,
          'hasPrev': targetPage > 1,
        };
      } else {
        _error = 'Lỗi kết nối: $e';
        _isOffline = false;
      }
    }

    _isLoading = false;
    notifyListeners();

    await _dbHelper.debugDatabase();
  }

  Future<void> syncStaffs() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('No network, skipping sync');
        return;
      }

      print('Syncing ${_role.toLowerCase()}s...');
      final result = _role == 'ADMIN'
          ? await StaffService.getAdmins(
        search: _searchQuery,
        page: _currentPage,
        limit: _limit,
        isMale: _isMale,
        email: _email,
        createdFrom: _createdFrom,
        createdTo: _createdTo,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      )
          : await StaffService.getDoctors(
        search: _searchQuery,
        page: _currentPage,
        limit: _limit,
        isMale: _isMale,
        email: _email,
        createdFrom: _createdFrom,
        createdTo: _createdTo,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (result['success'] == true) {
        final data = result['data'] as List<dynamic>;
        print('Synced ${data.length} ${_role.toLowerCase()}s from API');

        final newStaffs = data.map((json) {
          try {
            return Staff.fromJson(json);
          } catch (e) {
            print('Error parsing staff from JSON: $e');
            print('Problematic JSON: $json');
            return null;
          }
        }).where((staff) => staff != null).cast<Staff>().toList();

        if (newStaffs.isNotEmpty) {
          await _dbHelper.clearStaffs();
          await _dbHelper.insertStaffs(newStaffs);
          print('Saved ${newStaffs.length} ${_role.toLowerCase()}s to database');
          _staffs = newStaffs;
          _meta = result['meta'] ?? {};
          _currentPage = _meta['page'] ?? 1;
          _isOffline = false;
          _error = null;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> nextPage() async {
    if (hasNext) {
      await fetchStaffs(page: _currentPage + 1);
    }
  }

  Future<void> prevPage() async {
    if (hasPrev) {
      await fetchStaffs(page: _currentPage - 1);
    }
  }

  Future<bool> deleteStaff(String id, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await StaffService.deleteStaff(id, password: password);
      if (success) {
        _staffs.removeWhere((staff) => staff.id == id);
        await _dbHelper.clearStaffs();
        await _dbHelper.insertStaffs(_staffs);
        print('Deleted staff $id and updated database');
      } else {
        _error = 'Failed to delete staff';
      }
      return success;
    } catch (e) {
      _error = 'Error deleting staff: $e';
      return false;
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