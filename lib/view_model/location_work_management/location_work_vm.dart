import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/work_location_service.dart';

import '../../model/entities/work_location.dart';
import '../../model/services/local/database_helper.dart';


class LocationWorkVm extends ChangeNotifier {
  List<WorkLocation> _locations = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _limit = 10;
  Map<String, dynamic> _meta = {};

  List<WorkLocation> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get total => _meta['total'] ?? 0;
  int get totalPages => _meta['totalPages'] ?? 1;
  bool get hasNext => _meta['hasNext'] ?? false;
  bool get hasPrev => _meta['hasPrev'] ?? false;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> fetchLocations({int? page, String? sortBy, String? sortOrder}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final targetPage = page ?? _currentPage;

    try {
      final result = await LocationWorkService.getAllLocations(
        page: targetPage,
        limit: _limit,
        sortBy: sortBy ?? 'name',
        sortOrder: sortOrder ?? 'DESC',
      );
      if (result['success'] == true) {
        _locations = (result['data'] as List<dynamic>)
            .map((json) => WorkLocation.fromJson(json))
            .toList();
        _meta = result['meta'] ?? {};
        _currentPage = _meta['page'] ?? 1;
        // Lưu page hiện tại vào db
        await _dbHelper.clearLocations();
        await _dbHelper.insertLocations(_locations);
      } else {
        _error = result['message'] ?? 'Failed to load locations from API';
        // Lấy từ db nếu offline
        _locations = await _dbHelper.getLocations();
        if (_locations.isEmpty) {
          _error = 'No offline data available';
        }
      }
    } catch (e) {
      _error = 'Error: $e';
      _locations = await _dbHelper.getLocations();
      if (_locations.isEmpty) {
        _error = 'No offline data available: $e';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> nextPage() async {
    if (hasNext) {
      await fetchLocations(page: _currentPage + 1);
    }
  }

  Future<void> prevPage() async {
    if (hasPrev) {
      await fetchLocations(page: _currentPage - 1);
    }
  }

  Future<bool> updateLocationIsActive(String id, bool isActive) async {
    _isLoading = true;
    notifyListeners();

    final success = await LocationWorkService.updateLocation(
      id: id,
      isActive: isActive,
    );

    if (success) {
      final index = _locations.indexWhere((loc) => loc.id == id);
      if (index != -1) {
        _locations[index] = WorkLocation(
          id: _locations[index].id,
          name: _locations[index].name,
          address: _locations[index].address,
          phone: _locations[index].phone,
          timezone: _locations[index].timezone,
          isActive: isActive,
          createdAt: _locations[index].createdAt,
          updatedAt: DateTime.now(),
        );
        await _dbHelper.insertLocations(_locations);
      }
    } else {
      _error = 'Failed to update isActive';
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