import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/specialty_service.dart';

class SpecialtyVm extends ChangeNotifier {
  List<dynamic> _specialties = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _error;
  Map<String, List<dynamic>> _infoSections = {};

  List<dynamic> get specialties => _specialties;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  Future<void> fetchSpecialties({bool refresh = false}) async {
    if (_isLoading || (!refresh && !_hasMore)) return;

    if (refresh) {
      _page = 1;
      _specialties.clear();
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await SpecialtyService.getAllSpecialties(page: _page);
    if (result['success'] == true) {
      _specialties.addAll(result['data'] ?? []);
      final meta = result['meta'];
      _hasMore = meta['hasNext'] ?? false;
      _page++;
    } else {
      _error = 'Failed to load specialties';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchInfoSections(String specialtyId) async {
    if (_infoSections.containsKey(specialtyId)) return;

    _isLoading = true;
    notifyListeners();

    final result = await SpecialtyService.getInfoSections(specialtyId);
    if (result['success'] == true) {
      _infoSections[specialtyId] = result['data'] ?? [];
    } else {
      _error = 'Failed to load info sections';
    }

    _isLoading = false;
    notifyListeners();
  }

  List<dynamic> getInfoSectionsFor(String specialtyId) {
    return _infoSections[specialtyId] ?? [];
  }

  Future<bool> createSpecialty({required String name, String? description}) async {
    final success = await SpecialtyService.createSpecialty(name: name, description: description);
    if (success) {
      fetchSpecialties(refresh: true);
    }
    return success;
  }

  Future<bool> updateSpecialty({required String id, String? name, String? description}) async {
    final success = await SpecialtyService.updateSpecialty(id: id, name: name, description: description);
    if (success) {
      fetchSpecialties(refresh: true);
    }
    return success;
  }

  Future<bool> deleteSpecialty(String id, String password) async {
    final success = await SpecialtyService.deleteSpecialty(id, password: password);
    if (success) {
      fetchSpecialties(refresh: true);
    }
    return success;
  }

  Future<bool> createInfoSection({required String specialtyId, required String name, required String content}) async {
    final success = await SpecialtyService.createInfoSection(specialtyId: specialtyId, name: name, content: content);
    if (success) {
      _infoSections.remove(specialtyId);
      await fetchInfoSections(specialtyId);
    }
    return success;
  }

  Future<bool> updateInfoSection({required String id, String? name, String? content}) async {
    final success = await SpecialtyService.updateInfoSection(id: id, name: name, content: content);
    if (success) {
      _infoSections.clear();
    }
    return success;
  }

  Future<bool> deleteInfoSection(String id, String specialtyId) async {
    final success = await SpecialtyService.deleteInfoSection(id);
    if (success) {
      _infoSections.remove(specialtyId);
      await fetchInfoSections(specialtyId);
    }
    return success;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}