import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
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

  DoctorDetail? _doctorDetail;
  bool _isLoadingDetail = false;


  List<Doctor> get doctors => _doctors;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isOffline => _isOffline;
  bool get hasNext => _meta['hasNext'] ?? false;

  bool? get isMale => _isMale;
  String? get sortBy => _sortBy;
  String? get sortOrder => _sortOrder;

  DoctorDetail? get doctorDetail => _doctorDetail;
  bool get isLoadingDetail => _isLoadingDetail;


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
        if (_doctorDetail != null) {
          fetchDoctorDetail(_doctorDetail!.id);
        }
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
      final offlineDoctors = await _dbHelper.getDoctors(
        role: _role,
        search: _searchQuery,
        isMale: _isMale,
        page: _currentPage,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (forceRefresh) {
        _doctors = offlineDoctors;
      } else {
        _doctors.addAll(offlineDoctors);
      }
      if (_doctors.isEmpty && forceRefresh) {
        _error = 'Không có dữ liệu offline.';
      }

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
        _currentPage++;

        if (_doctors.isNotEmpty && _currentPage == 2 && _searchQuery.isEmpty && _isMale == null) {
          await _dbHelper.clearDoctors(role: _role);
          await _dbHelper.insertDoctors(_doctors);
        }
      } else {
        _error = result.message;
        if (forceRefresh) { // Try loading offline data if API fails on refresh
          _doctors = await _dbHelper.getDoctors(
            role: _role,
            search: _searchQuery,
            isMale: _isMale,
            page: 1, // Reset to page 1 for offline
            limit: _limit,
            sortBy: _sortBy,
            sortOrder: _sortOrder,
          );
          if (_doctors.isEmpty) {
            _error = result.message + " Không có dữ liệu offline.";
          } else {
            _error = result.message + " Đang hiển thị dữ liệu offline.";
          }
        }
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      if (forceRefresh) { // Try loading offline data on connection error
        _doctors = await _dbHelper.getDoctors(
          role: _role,
          search: _searchQuery,
          isMale: _isMale,
          page: 1, // Reset to page 1 for offline
          limit: _limit,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
        if (_doctors.isEmpty) {
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

  Future<void> fetchDoctorDetail(String doctorId, {bool isSelf = false}) async {
    _isLoadingDetail = true;
    _doctorDetail = null;
    _error = null;
    notifyListeners();

    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = !connectivityResult.contains(ConnectivityResult.none);
    _isOffline = !isConnected;

    try {
      if (isConnected) {
        if (isSelf) {
          _doctorDetail = await DoctorService.getSelfProfileComplete();
        } else {
          _doctorDetail = await DoctorService.getDoctorWithProfile(doctorId);
        }
        if (_doctorDetail == null) {
          _error = "Không tìm thấy thông tin bác sĩ hoặc có lỗi xảy ra.";
        }
      } else {
        _error = "Bạn đang offline, không thể tải chi tiết.";
      }
    } catch (e) {
      _error = "Lỗi khi tải chi tiết bác sĩ: $e";
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }


  Future<bool> createDoctorProfile(Map<String, dynamic> data) async {
    final profile = await DoctorService.createDoctorProfile(data);
    return profile != null;
  }

  Future<bool> updateDoctorProfile(String profileId, Map<String, dynamic> data) async {
    final profile = await DoctorService.updateDoctorProfile(profileId, data);
    if (profile != null && _doctorDetail != null && _doctorDetail!.profileId == profileId) {
      await fetchDoctorDetail(_doctorDetail!.id);
    }
    return profile != null;
  }

  Future<bool> updateSelfProfile(Map<String, dynamic> data) async {
    bool success = false;
    _error = null; // Clear previous errors
    notifyListeners(); // Indicate loading potentially
    try {
      final profile = await DoctorService.updateSelfProfile(data);
      success = profile != null;
      if (success && _doctorDetail != null && _doctorDetail!.profileId == profile!.id) {
        await fetchDoctorDetail(_doctorDetail!.id, isSelf: true); // Refetch self profile
      } else if (!success) {
        _error = "Cập nhật hồ sơ thất bại.";
      }
    } catch (e) {
      _error = "Lỗi khi cập nhật hồ sơ: $e";
      success = false;
    } finally {
      notifyListeners(); // Notify UI about success/failure/new data
    }
    return success;
  }

  Future<void> toggleDoctorStatus(String profileId, bool isActive) async {
    if (_doctorDetail == null) {
      print("🔴 [VM-ERROR] _doctorDetail is null. Cannot proceed.");
      _error = "Không có thông tin chi tiết bác sĩ để cập nhật.";
      notifyListeners();
      return;
    }
    _error = null; // Clear previous errors


    final originalStatus = _doctorDetail!.isActive;
    // Optimistic UI update
    _doctorDetail = _doctorDetail!.copyWith(isActive: isActive);
    notifyListeners();


    print("--- START: Toggle Doctor Status ---");
    print("🧠 [VM] Requesting isActive = $isActive for profileId: $profileId");


    final updatedProfile = await DoctorService.toggleDoctorActive(profileId, isActive);

    if (updatedProfile != null) {
      print("✅ [VM] API call successful. isActive from API: ${updatedProfile.isActive}");

      _doctorDetail = _doctorDetail!.copyWith(
        isActive: updatedProfile.isActive, // Use status from API response
        profileUpdatedAt: updatedProfile.updatedAt,
      );

    } else {
      print("❌ [VM-ERROR] API call failed or returned null.");
      _error = "Cập nhật trạng thái thất bại.";
      // Revert optimistic update
      _doctorDetail = _doctorDetail!.copyWith(isActive: originalStatus);

    }
    notifyListeners(); // Notify UI about the final state (success or reverted error)
    print("--- END: Toggle Doctor Status ---");
  }

  Future<void> loadMore() async {
    if (hasNext && !_isLoading && !_isLoadingMore && !_isOffline) {
      await fetchDoctors();
    }
  }

  Future<bool> deleteDoctor(String id, String password) async {
    _error = null;
    bool success = false;
    try {
      success = await DoctorService.deleteDoctor(id, password: password);
      if (success) {
        _doctors.removeWhere((doctor) => doctor.id == id);
        await _dbHelper.deleteDoctor(id);
      } else {
        _error = "Xóa bác sĩ thất bại. Vui lòng kiểm tra lại mật khẩu.";
      }
    } catch (e) {
      _error = "Lỗi khi xóa bác sĩ: $e";
      success = false;
    }
    notifyListeners();
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}