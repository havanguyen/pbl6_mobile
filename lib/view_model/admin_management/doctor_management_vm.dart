import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/services/local/doctor_database_helper.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';

class DoctorVm extends ChangeNotifier {
  List<Doctor> _doctors = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _isOffline = false;
  int _currentPage = 1;
  final int _limit = 10;
  Map<String, dynamic> _meta = {};
  final String _role = 'DOCTOR';

  String _searchQuery = '';
  bool? _isMale;
  String? _sortBy = 'createdAt';
  String? _sortOrder = 'desc';

  List<Doctor> get doctors => _doctors;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isOffline => _isOffline;
  bool get hasNext => _meta['hasNext'] ?? false;

  bool? get isMale => _isMale;
  String? get sortBy => _sortBy;
  String? get sortOrder => _sortOrder;

  final DoctorDatabaseHelper _dbHelper = DoctorDatabaseHelper.instance;

  DoctorVm() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isConnected = results.any((result) =>
      result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile);
      if (isConnected && _isOffline) {
        _isOffline = false;
        fetchDoctors(forceRefresh: true);
      }
    });
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    fetchDoctors(forceRefresh: true);
  }

  void updateGenderFilter(bool? gender) {
    _isMale = gender;
    fetchDoctors(forceRefresh: true);
  }

  void updateSortFilter({String? sortBy, String? sortOrder}) {
    _sortBy = sortBy ?? _sortBy;
    _sortOrder = sortOrder ?? _sortOrder;
    fetchDoctors(forceRefresh: true);
  }

  void resetFilters() {
    _searchQuery = '';
    _isMale = null;
    _sortBy = 'createdAt';
    _sortOrder = 'desc';
    fetchDoctors(forceRefresh: true);
  }

  Future<void> fetchDoctors({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _currentPage = 1;
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
      final offlineDoctors = await _dbHelper.getDoctors(
        role: _role,
        search: _searchQuery,
        isMale: _isMale,
        page: _currentPage,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      _doctors = offlineDoctors;
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
      return;
    }

    try {
      final result = await DoctorService.getDoctors(
        search: _searchQuery,
        page: _currentPage,
        limit: _limit,
        isMale: _isMale,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (result.success) {
        if (forceRefresh) {
          _doctors = result.data;
        } else {
          _doctors.addAll(result.data);
        }
        _meta = result.meta;

        if (_doctors.isNotEmpty && _currentPage == 1) {
          await _dbHelper.clearDoctors(role: _role);
          await _dbHelper.insertDoctors(_doctors);
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
      await fetchDoctors();
    }
  }

  Future<bool> deleteDoctor(String id, String password) async {
    final success = await DoctorService.deleteDoctor(id, password: password);
    if (success) {
      _doctors.removeWhere((doctor) => doctor.id == id);
      await _dbHelper.deleteDoctor(id);
      notifyListeners();
    }
    return success;
  }
}