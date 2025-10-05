import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/staff_service.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/model/services/local/staff_database_helper.dart';

class StaffVm extends ChangeNotifier {
  List<Staff> _staffs = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _limit = 10;
  Map<String, dynamic> _meta = {};
  String _role = 'ADMIN';

  // Filter properties
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
  int get currentPage => _currentPage;
  int get total => _meta['total'] ?? 0;
  int get totalPages => _meta['totalPages'] ?? 1;
  bool get hasNext => _meta['hasNext'] ?? false;
  bool get hasPrev => _meta['hasPrev'] ?? false;
  String get role => _role;

  // Filter getters
  String get searchQuery => _searchQuery;
  bool? get isMale => _isMale;
  String? get email => _email;
  String? get createdFrom => _createdFrom;
  String? get createdTo => _createdTo;
  String? get sortBy => _sortBy;
  String? get sortOrder => _sortOrder;

  final StaffDatabaseHelper _dbHelper = StaffDatabaseHelper.instance;

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
    notifyListeners();
  }

  Future<void> fetchStaffs({int? page, bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final targetPage = page ?? _currentPage;

    try {
      print('Fetching ${_role.toLowerCase()}s...');

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

        // Lưu vào database
        if (_staffs.isNotEmpty) {
          await _dbHelper.insertStaffs(_staffs);
          print('Saved ${_staffs.length} ${_role.toLowerCase()}s to database');
        }

      } else {
        final apiError = result['message'] ?? 'Failed to load ${_role.toLowerCase()}s from API';
        print('API error: $apiError');

        // Thử lấy từ database
        print('Trying to load from database...');
        final offlineStaffs = await _dbHelper.getStaffs();

        if (offlineStaffs.isNotEmpty) {
          print('Loaded ${offlineStaffs.length} ${_role.toLowerCase()}s from database');
          _staffs = offlineStaffs;
          _error = 'Đang sử dụng dữ liệu offline';
        } else {
          _error = apiError;
        }
      }
    } catch (e) {
      print('Network error: $e');

      // Thử lấy từ database khi có lỗi mạng
      final offlineStaffs = await _dbHelper.getStaffs();

      if (offlineStaffs.isNotEmpty) {
        print('Network error, loaded ${offlineStaffs.length} ${_role.toLowerCase()}s from database');
        _staffs = offlineStaffs;
        _error = 'Mất kết nối. Đang sử dụng dữ liệu offline';
      } else {
        _error = 'Lỗi kết nối: $e';
      }
    }

    _isLoading = false;
    notifyListeners();

    // Debug database
    await _dbHelper.debugDatabase();
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

    final success = await StaffService.deleteStaff(id, password: password);

    if (success) {
      _staffs.removeWhere((staff) => staff.id == id);
      await _dbHelper.insertStaffs(_staffs);
    } else {
      _error = 'Failed to delete staff';
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