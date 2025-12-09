import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/info_section.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/services/local/specialty_database_helper.dart';
import 'package:pbl6mobile/model/services/remote/specialty_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pbl6mobile/model/services/remote/utilities_service.dart';

class SpecialtyVm extends ChangeNotifier {
  List<Specialty> _specialties = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  final int _limit = 10;
  Map<String, dynamic> _meta = {};

  List<Specialty> _allSpecialties = [];
  bool _isFetchingAll = false;

  String? _error;
  bool _isOffline = false;
  String _searchQuery = '';
  String? _sortBy = 'createdAt';

  String? _sortOrder = 'DESC';
  bool? _isActive;

  Map<String, List<InfoSection>> _infoSections = {};
  bool _isInfoSectionLoading = false;

  File? _selectedIconFile;
  String? _uploadedIconUrl;
  bool _isUploadingIcon = false;
  String? _iconUploadError;

  File? get selectedIconFile => _selectedIconFile;
  String? get uploadedIconUrl => _uploadedIconUrl;
  bool get isUploadingIcon => _isUploadingIcon;
  String? get iconUploadError => _iconUploadError;

  List<Specialty> get specialties => _specialties;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasNext => _meta['hasNext'] ?? false;

  List<Specialty> get allSpecialties => _allSpecialties;
  bool get isLoadingAll => _isFetchingAll;

  String? get error => _error;
  bool get isOffline => _isOffline;
  bool get isInfoSectionLoading => _isInfoSectionLoading;

  final SpecialtyDatabaseHelper _dbHelper = SpecialtyDatabaseHelper.instance;

  SpecialtyVm() {
    Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      bool isConnected = results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile,
      );
      if (isConnected && _isOffline) {
        _isOffline = false;
        fetchSpecialties(forceRefresh: true);
      }
    });
  }

  Future<void> fetchAllSpecialties() async {
    print('--- [DEBUG] SpecialtyVm.fetchAllSpecialties (Public) ---');
    if (_allSpecialties.isNotEmpty || _isFetchingAll) {
      return;
    }

    _isFetchingAll = true;
    _error = null;
    notifyListeners();

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _error = 'Không có kết nối mạng';
      _isFetchingAll = false;
      notifyListeners();
      return;
    }

    try {
      // Use public endpoint to avoid 403 Forbidden for Doctors
      final results = await SpecialtyService.getPublicSpecialties();
      _allSpecialties = results;
      print('Total specialties fetched: ${_allSpecialties.length}');
    } catch (e) {
      print('Error dealing with fetch public: $e');
      _error = 'Lỗi khi tải tất cả chuyên khoa: $e';
      _allSpecialties = [];
    } finally {
      _isFetchingAll = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    fetchSpecialties(forceRefresh: true);
  }

  void updateSortFilter({String? sortBy, String? sortOrder}) {
    _sortBy = sortBy ?? _sortBy;
    _sortOrder = sortOrder ?? _sortOrder;
    fetchSpecialties(forceRefresh: true);
  }

  void resetFilters() {
    _searchQuery = '';
    _sortBy = 'createdAt';
    _sortOrder = 'DESC';
    fetchSpecialties(forceRefresh: true);
  }

  Future<void> fetchSpecialties({bool forceRefresh = false}) async {
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

    if (forceRefresh) {
      final offlineData = await _dbHelper.getSpecialties(
        search: _searchQuery,
        page: 1,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      _specialties = offlineData;
      notifyListeners();
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = !connectivityResult.contains(ConnectivityResult.none);
    _isOffline = !isConnected;

    if (!isConnected) {
      _error = 'Bạn đang offline. Dữ liệu có thể đã cũ.';
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
      return;
    }

    try {
      final result = await SpecialtyService.getAllSpecialties(
        search: _searchQuery,
        page: _currentPage,

        limit: _limit,
        sortBy: _sortBy!,
        sortOrder: _sortOrder!,
        isActive: _isActive,
      );

      if (result.success) {
        if (forceRefresh) {
          _specialties = result.data;
        } else {
          _specialties.addAll(result.data);
        }
        _meta = result.meta;
        _currentPage++;

        await _dbHelper.insertSpecialties(result.data);
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

  Future<void> fetchInfoSections(
    String specialtyId, {
    bool forceRefresh = false,
  }) async {
    if (_infoSections.containsKey(specialtyId) && !forceRefresh) return;

    _isInfoSectionLoading = true;
    notifyListeners();

    try {
      final offlineSections = await _dbHelper.getInfoSections(specialtyId);
      _infoSections[specialtyId] = offlineSections;
      notifyListeners();
    } catch (e) {
      print("Lỗi tải cache info sections: $e");
    }

    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = !connectivityResult.contains(ConnectivityResult.none);
    _isOffline = !isConnected;

    if (!isConnected) {
      _isInfoSectionLoading = false;
      notifyListeners();
      return;
    }

    try {
      final result = await SpecialtyService.getInfoSections(specialtyId);
      if (result['success'] == true) {
        final sections = (result['data'] as List)
            .map((json) => InfoSection.fromJson(json))
            .toList();
        _infoSections[specialtyId] = sections;

        if (sections.isNotEmpty) {
          await _dbHelper.clearInfoSections(specialtyId);
          await _dbHelper.insertInfoSections(sections);
        }
      } else {
        _error = 'Failed to load info sections';
      }
    } catch (e) {
      _error = 'Lỗi kết nối khi tải chi tiết: $e';
    }

    _isInfoSectionLoading = false;
    notifyListeners();
  }

  Future<void> pickIconImage() async {
    _selectedIconFile = null;
    _iconUploadError = null;
    _uploadedIconUrl = null;
    notifyListeners();
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512, // Icons don't need to be huge
        maxHeight: 512,
      );
      if (pickedFile != null) {
        _selectedIconFile = File(pickedFile.path);
        notifyListeners();
        await uploadIconImage();
      }
    } catch (e) {
      _iconUploadError = "Error selecting image: $e";
      notifyListeners();
    }
  }

  Future<String?> uploadIconImage() async {
    if (_selectedIconFile == null) return null;
    if (!await _checkConnectivity()) {
      _iconUploadError = 'You are offline. Cannot upload image.';
      notifyListeners();
      return null;
    }

    _isUploadingIcon = true;
    _iconUploadError = null;
    notifyListeners();

    String? imageUrl;
    Map<String, dynamic>? signatureData;

    try {
      signatureData = await UtilitiesService.getUploadSignature();
      if (signatureData == null) {
        _iconUploadError = "Cannot get upload signature.";
        _isUploadingIcon = false;
        notifyListeners();
        return null;
      }

      imageUrl = await UtilitiesService.uploadImageToCloudinary(
        _selectedIconFile!.path,
        signatureData,
      );

      if (imageUrl != null) {
        _uploadedIconUrl = imageUrl;
      } else {
        _iconUploadError = "Failed to upload image to Cloudinary.";
      }
    } catch (e) {
      _iconUploadError = "Upload failed: $e";
    } finally {
      _isUploadingIcon = false;
      notifyListeners();
    }
    return imageUrl;
  }

  void resetIconState() {
    _selectedIconFile = null;
    _uploadedIconUrl = null;
    _iconUploadError = null;
    _isUploadingIcon = false;
    notifyListeners();
  }

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  List<InfoSection> getInfoSectionsFor(String specialtyId) {
    return _infoSections[specialtyId] ?? [];
  }

  Future<bool> createSpecialty({
    required String name,
    String? description,
    String? iconUrl,
  }) async {
    final success = await SpecialtyService.createSpecialty(
      name: name,
      description: description,
      iconUrl: iconUrl,
    );
    if (success) {
      fetchSpecialties(forceRefresh: true);
    }
    return success;
  }

  Future<bool> updateSpecialty({
    required String id,
    String? name,
    String? description,
    String? iconUrl,
  }) async {
    final success = await SpecialtyService.updateSpecialty(
      id: id,
      name: name,
      description: description,
      iconUrl: iconUrl,
    );
    if (success) {
      fetchSpecialties(forceRefresh: true);
    }
    return success;
  }

  Future<bool> deleteSpecialty(String id, String password) async {
    final success = await SpecialtyService.deleteSpecialty(
      id,
      password: password,
    );
    if (success) {
      _specialties.removeWhere((s) => s.id == id);
      await _dbHelper.deleteSpecialty(id);
      notifyListeners();
    }
    return success;
  }

  Future<bool> createInfoSection({
    required String specialtyId,
    required String name,
    required String content,
  }) async {
    final success = await SpecialtyService.createInfoSection(
      specialtyId: specialtyId,
      name: name,
      content: content,
    );
    if (success) {
      await fetchInfoSections(specialtyId, forceRefresh: true);
    }
    return success;
  }

  Future<bool> updateInfoSection({
    required String id,
    String? name,
    String? content,
  }) async {
    final success = await SpecialtyService.updateInfoSection(
      id: id,
      name: name,
      content: content,
    );
    if (success) {
      _infoSections.clear();
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteInfoSection(
    String id,
    String specialtyId,
    String password,
  ) async {
    final success = await SpecialtyService.deleteInfoSection(
      id,
      password: password,
    );
    if (success) {
      await fetchInfoSections(specialtyId, forceRefresh: true);
    }
    return success;
  }
}
