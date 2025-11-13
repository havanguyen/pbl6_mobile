import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/info_section.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/services/local/specialty_database_helper.dart';
import 'package:pbl6mobile/model/services/remote/specialty_service.dart';

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

  Map<String, List<InfoSection>> _infoSections = {};
  bool _isInfoSectionLoading = false;

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
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isConnected = results.any((result) =>
      result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile);
      if (isConnected && _isOffline) {
        _isOffline = false;
        fetchSpecialties(forceRefresh: true);
      }
    });
  }

  Future<void> fetchAllSpecialties() async {
    if (_allSpecialties.isNotEmpty || _isFetchingAll) return;

    _isFetchingAll = true;
    _error = null;
    notifyListeners();

    final List<Specialty> results = [];
    int currentPage = 1;
    bool hasMore = true;
    const int safeLimit = 50;

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _error = 'Không có kết nối mạng';
      _isFetchingAll = false;
      notifyListeners();
      return;
    }

    try {
      while (hasMore) {
        final result = await SpecialtyService.getAllSpecialties(
          page: currentPage,
          limit: safeLimit,
        );

        if (result.success) {
          results.addAll(result.data);
          hasMore = result.meta['hasNext'] ?? false;
          if (hasMore) {
            currentPage++;
          }
        } else {
          _error = result.message;
          hasMore = false;
        }
      }
      _allSpecialties = results;
    } catch (e) {
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

  Future<void> fetchInfoSections(String specialtyId,
      {bool forceRefresh = false}) async {
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

  List<InfoSection> getInfoSectionsFor(String specialtyId) {
    return _infoSections[specialtyId] ?? [];
  }

  Future<bool> createSpecialty(
      {required String name, String? description}) async {
    final success =
    await SpecialtyService.createSpecialty(name: name, description: description);
    if (success) {
      fetchSpecialties(forceRefresh: true);
    }
    return success;
  }

  Future<bool> updateSpecialty(
      {required String id, String? name, String? description}) async {
    final success = await SpecialtyService.updateSpecialty(
        id: id, name: name, description: description);
    if (success) {
      fetchSpecialties(forceRefresh: true);
    }
    return success;
  }

  Future<bool> deleteSpecialty(String id, String password) async {
    final success =
    await SpecialtyService.deleteSpecialty(id, password: password);
    if (success) {
      _specialties.removeWhere((s) => s.id == id);
      await _dbHelper.deleteSpecialty(id);
      notifyListeners();
    }
    return success;
  }

  Future<bool> createInfoSection(
      {required String specialtyId,
        required String name,
        required String content}) async {
    final success = await SpecialtyService.createInfoSection(
        specialtyId: specialtyId, name: name, content: content);
    if (success) {
      await fetchInfoSections(specialtyId, forceRefresh: true);
    }
    return success;
  }

  Future<bool> updateInfoSection(
      {required String id, String? name, String? content}) async {
    final success = await SpecialtyService.updateInfoSection(
        id: id, name: name, content: content);
    if (success) {
      _infoSections.clear();
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteInfoSection(
      String id, String specialtyId, String password) async {
    final success =
    await SpecialtyService.deleteInfoSection(id, password: password);
    if (success) {
      await fetchInfoSections(specialtyId, forceRefresh: true);
    }
    return success;
  }
}