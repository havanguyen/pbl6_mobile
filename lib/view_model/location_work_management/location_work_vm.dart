import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/services/remote/work_location_service.dart';

class LocationWorkVm extends ChangeNotifier {
  List<dynamic> _locations = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLocations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await LocationWorkService.getAllLocations();
    if (result['success'] == true) {
      _locations = result['data'] ?? [];
    } else {
      _error = 'Failed to load locations';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}