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
  String? _error;
  bool _isOffline = false;
  int _currentPage = 1;
  final int _limit = 10;
  Map<String, dynamic> _meta = {};

  String _searchQuery = '';
  String? _sortBy = 'createdAt';
  String? _sortOrder = 'DESC';

  Map<String, List<InfoSection>> _infoSections = {};
  bool _isInfoSectionLoading = false;

  List<Specialty> get specialties => _specialties;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isOffline => _isOffline;
  bool get hasNext => _meta['hasNext'] ?? false;
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

    if (_specialties.isNotEmpty && !forceRefresh) return;
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
      final offlineData = await _dbHelper.getSpecialties(
        search: _searchQuery,
        page: _currentPage,
        limit: _limit,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );
      if (forceRefresh) {
        _specialties = offlineData;
      } else {
        _specialties.addAll(offlineData);
      }
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

        // Cache data only on the first page of a fresh fetch
        if (_specialties.isNotEmpty && _currentPage == 2 && _searchQuery.isEmpty) {
          await _dbHelper.clearSpecialties();
          await _dbHelper.insertSpecialties(_specialties);
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

  Future<void> fetchInfoSections(String specialtyId,
      {bool forceRefresh = false}) async {
    if (_infoSections.containsKey(specialtyId) && !forceRefresh) return;

    _isInfoSectionLoading = true;
    notifyListeners();

    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = !connectivityResult.contains(ConnectivityResult.none);
    _isOffline = !isConnected;

    if (!isConnected) {
      final offlineSections = await _dbHelper.getInfoSections(specialtyId);
      _infoSections[specialtyId] = offlineSections;
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
    final success = await SpecialtyService.deleteInfoSection(id, password: password);
    if (success) {
      await fetchInfoSections(specialtyId, forceRefresh: true);
    }
    return success;
  }
}