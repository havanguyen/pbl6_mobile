import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/model/entities/review.dart';
import 'package:pbl6mobile/model/services/local/doctor_database_helper.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/model/services/remote/review_service.dart';
import 'package:pbl6mobile/model/services/remote/utilities_service.dart';

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

  String? selectedAvatarPath;
  String? selectedPortraitPath;
  bool _isUploadingAvatar = false;
  bool _isUploadingPortrait = false;
  String? _uploadError;

  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  String? _reviewError;

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

  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isUploadingPortrait => _isUploadingPortrait;
  String? get uploadError => _uploadError;

  List<Review> get reviews => _reviews;
  bool get isLoadingReviews => _isLoadingReviews;
  String? get reviewError => _reviewError;

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

        if (_doctors.isNotEmpty &&
            _currentPage == 2 &&
            _searchQuery.isEmpty &&
            _isMale == null) {
          await _dbHelper.clearDoctors(role: _role);
          await _dbHelper.insertDoctors(_doctors);
        }
      } else {
        _error = result.message;
        if (forceRefresh) {
          _doctors = await _dbHelper.getDoctors(
            role: _role,
            search: _searchQuery,
            isMale: _isMale,
            page: 1,
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
      if (forceRefresh) {
        _doctors = await _dbHelper.getDoctors(
          role: _role,
          search: _searchQuery,
          isMale: _isMale,
          page: 1,
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
    _reviews = [];
    _reviewError = null;
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
        if (_doctorDetail != null) {
          await fetchReviewPreview(_doctorDetail!.id);
        } else {
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

  void clearUploadError() {
    if (_uploadError != null) {
      _uploadError = null;
      notifyListeners();
    }
  }

  Future<void> pickAvatarImage() async {
    _uploadError = null;
    notifyListeners();
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
      if (image != null) {
        selectedAvatarPath = image.path;
        notifyListeners();
      }
    } catch (e) {
      _uploadError = "Lỗi khi chọn ảnh đại diện: $e";
      print(_uploadError);
      notifyListeners();
    }
  }

  Future<void> pickPortraitImage() async {
    _uploadError = null;
    notifyListeners();
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
      if (image != null) {
        selectedPortraitPath = image.path;
        notifyListeners();
      }
    } catch (e) {
      _uploadError = "Lỗi khi chọn ảnh bìa: $e";
      print(_uploadError);
      notifyListeners();
    }
  }

  Future<String?> _uploadImage(String? filePath, bool isAvatar) async {
    if (filePath == null) return null;

    final fieldName = isAvatar ? "avatar" : "portrait";

    if (isAvatar) {
      _isUploadingAvatar = true;
    } else {
      _isUploadingPortrait = true;
    }
    _uploadError = null;
    notifyListeners();

    String? imageUrl;
    try {
      print("⏳ [DoctorVm] Bắt đầu upload $fieldName...");
      final signatureData = await UtilitiesService.getUploadSignature();
      if (signatureData != null) {
        imageUrl =
        await UtilitiesService.uploadImageToCloudinary(filePath, signatureData);
        if (imageUrl == null) {
          _uploadError = 'Lỗi: Không thể upload $fieldName lên Cloudinary.';
          print("❌ [DoctorVm] $_uploadError");
        } else {
          print("✅ [DoctorVm] Upload $fieldName thành công: $imageUrl");
        }
      } else {
        _uploadError = 'Lỗi: Không thể lấy chữ ký upload cho $fieldName.';
        print("❌ [DoctorVm] $_uploadError");
      }
    } catch (e) {
      _uploadError = 'Lỗi khi đang upload $fieldName: $e';
      print("🔥 [DoctorVm] $_uploadError");
    } finally {
      if (isAvatar) {
        _isUploadingAvatar = false;
      } else {
        _isUploadingPortrait = false;
      }
      notifyListeners();
    }
    return imageUrl;
  }

  Future<bool> createDoctorProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    _uploadError = null;
    notifyListeners();

    bool success = false;
    try {
      final Map<String, dynamic> dataToSend = Map.from(data);

      if (selectedAvatarPath != null) {
        final newAvatarUrl = await _uploadImage(selectedAvatarPath, true);
        if (newAvatarUrl == null) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        dataToSend['avatarUrl'] = newAvatarUrl;
      }

      if (selectedPortraitPath != null) {
        final newPortraitUrl = await _uploadImage(selectedPortraitPath, false);
        if (newPortraitUrl == null) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        dataToSend['portrait'] = newPortraitUrl;
      }

      print("⏳ [DoctorVm] Calling DoctorService.createDoctorProfile...");
      final profile = await DoctorService.createDoctorProfile(dataToSend);
      success = profile != null;

      if (success) {
        print("✅ [DoctorVm] createDoctorProfile successful.");
        selectedAvatarPath = null;
        selectedPortraitPath = null;
      } else {
        _error = "Tạo hồ sơ thất bại.";
        print("❌ [DoctorVm] createDoctorProfile failed.");
      }
    } catch (e) {
      _error = "Lỗi khi tạo hồ sơ: $e";
      print("🔥 [DoctorVm] Error in createDoctorProfile: $e");
      success = false;
    } finally {
      _isLoading = false;
      _isUploadingAvatar = false;
      _isUploadingPortrait = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateDoctorProfile(
      String profileId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    _uploadError = null;
    notifyListeners();

    bool success = false;
    try {
      final Map<String, dynamic> dataToSend = Map.from(data);

      if (selectedAvatarPath != null) {
        final newAvatarUrl = await _uploadImage(selectedAvatarPath, true);
        if (newAvatarUrl == null) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        dataToSend['avatarUrl'] = newAvatarUrl;
      } else if (dataToSend.containsKey('avatarUrl') &&
          dataToSend['avatarUrl'] == null) {
        dataToSend['avatarUrl'] = null;
      }

      if (selectedPortraitPath != null) {
        final newPortraitUrl = await _uploadImage(selectedPortraitPath, false);
        if (newPortraitUrl == null) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        dataToSend['portrait'] = newPortraitUrl;
      } else if (dataToSend.containsKey('portrait') &&
          dataToSend['portrait'] == null) {
        dataToSend['portrait'] = null;
      }

      print("⏳ [DoctorVm] Calling DoctorService.updateDoctorProfile...");
      final profile =
      await DoctorService.updateDoctorProfile(profileId, dataToSend);
      success = profile != null;

      if (success) {
        print("✅ [DoctorVm] updateDoctorProfile successful.");
        selectedAvatarPath = null;
        selectedPortraitPath = null;
        if (_doctorDetail != null && _doctorDetail!.profileId == profileId) {
          await fetchDoctorDetail(_doctorDetail!.id);
        }
      } else {
        _error = "Cập nhật hồ sơ thất bại.";
        print("❌ [DoctorVm] updateDoctorProfile failed.");
      }
    } catch (e) {
      _error = "Lỗi khi cập nhật hồ sơ: $e";
      print("🔥 [DoctorVm] Error in updateDoctorProfile: $e");
      success = false;
    } finally {
      _isLoading = false;
      _isUploadingAvatar = false;
      _isUploadingPortrait = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateSelfProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    _uploadError = null;
    notifyListeners();

    bool success = false;
    try {
      final Map<String, dynamic> dataToSend = Map.from(data);

      if (selectedAvatarPath != null) {
        final newAvatarUrl = await _uploadImage(selectedAvatarPath, true);
        if (newAvatarUrl == null) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        dataToSend['avatarUrl'] = newAvatarUrl;
      } else if (dataToSend.containsKey('avatarUrl') &&
          dataToSend['avatarUrl'] == null) {
        dataToSend['avatarUrl'] = null;
      }

      if (selectedPortraitPath != null) {
        final newPortraitUrl = await _uploadImage(selectedPortraitPath, false);
        if (newPortraitUrl == null) {
          _isLoading = false;
          notifyListeners();
          return false;
        }
        dataToSend['portrait'] = newPortraitUrl;
      } else if (dataToSend.containsKey('portrait') &&
          dataToSend['portrait'] == null) {
        dataToSend['portrait'] = null;
      }

      print("⏳ [DoctorVm] Calling DoctorService.updateSelfProfile...");
      final profile = await DoctorService.updateSelfProfile(dataToSend);
      success = profile != null;

      if (success) {
        print("✅ [DoctorVm] updateSelfProfile successful.");
        selectedAvatarPath = null;
        selectedPortraitPath = null;
        if (_doctorDetail != null) {
          await fetchDoctorDetail(_doctorDetail!.id, isSelf: true);
        }
      } else {
        _error = "Cập nhật hồ sơ thất bại.";
        print("❌ [DoctorVm] updateSelfProfile failed.");
      }
    } catch (e) {
      _error = "Lỗi khi cập nhật hồ sơ: $e";
      print("🔥 [DoctorVm] Error in updateSelfProfile: $e");
      success = false;
    } finally {
      _isLoading = false;
      _isUploadingAvatar = false;
      _isUploadingPortrait = false;
      notifyListeners();
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
    _error = null;

    final originalStatus = _doctorDetail!.isActive;
    _doctorDetail = _doctorDetail!.copyWith(isActive: isActive);
    notifyListeners();

    print("--- START: Toggle Doctor Status ---");
    print("🧠 [VM] Requesting isActive = $isActive for profileId: $profileId");

    final updatedProfile =
    await DoctorService.toggleDoctorActive(profileId, isActive);

    if (updatedProfile != null) {
      print(
          "✅ [VM] API call successful. isActive from API: ${updatedProfile.isActive}");

      _doctorDetail = _doctorDetail!.copyWith(
        isActive: updatedProfile.isActive,
        profileUpdatedAt: updatedProfile.updatedAt,
      );
    } else {
      print("❌ [VM-ERROR] API call failed or returned null.");
      _error = "Cập nhật trạng thái thất bại.";
      _doctorDetail = _doctorDetail!.copyWith(isActive: originalStatus);
    }
    notifyListeners();
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

  Future<void> fetchReviewPreview(String doctorId) async {
    _isLoadingReviews = true;
    _reviewError = null;
    notifyListeners();

    try {
      final result = await ReviewService.getReviewsForDoctor(
        doctorId: doctorId,
        page: 1,
        limit: 5,
      );

      if (result.success) {
        _reviews = result.data;
      } else {
        _reviewError = result.message;
      }
    } catch (e) {
      _reviewError = 'Lỗi kết nối: $e';
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }
}