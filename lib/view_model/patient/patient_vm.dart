import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/model/services/local/patient_database_helper.dart';
import 'package:pbl6mobile/model/services/remote/patient_service.dart';

class PatientVm extends ChangeNotifier {
  final PatientService _patientService = PatientService();
  final PatientDatabaseHelper _dbHelper = PatientDatabaseHelper();

  List<Patient> patients = [];
  bool isLoading = false;
  bool isFirstLoad = true;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  int _page = 1;
  final int _limit = 10;
  int _total = 0;
  bool _hasNext = true;

  bool _includeDeleted = false;
  bool get includeDeleted => _includeDeleted;

  Future<void> loadPatients({bool isRefresh = false}) async {
    if (isLoading || (_isLoadingMore && !isRefresh)) return;

    if (isRefresh) {
      _page = 1;
      _hasNext = true;
      patients.clear();
      isLoading = true;
    } else if (isFirstLoad) {
      isLoading = true;
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    if (isFirstLoad) {
      final cachedPatients = await _dbHelper.getCachedPatients();
      if (cachedPatients.isNotEmpty) {
        patients = cachedPatients;
        isLoading = false;
        notifyListeners();
      }
    }

    try {
      if (_hasNext) {
        final result = await _patientService.getPatients(
          page: _page,
          limit: _limit,
          includedDeleted: _includeDeleted,
        );

        final List<Patient> fetchedPatients = result['patients'] ?? [];
        final meta = result['meta'];

        if (meta != null) {
          _total = meta['total'];
          _hasNext = meta['hasNext'] ?? false;
        }

        if (isRefresh) {
          patients.clear();
        }

        patients.addAll(fetchedPatients);
        _page++;
      }
    } catch (e) {
      print("Error loading patients: $e");
    } finally {
      isLoading = false;
      isFirstLoad = false;
      _isLoadingMore = false;
      notifyListeners();

      if (isRefresh) {
        await _dbHelper.cachePatients(patients);
      }
    }
  }

  Future<bool> addPatient(Map<String, dynamic> data) async {
    final success = await _patientService.createPatient(data);
    if (success) {
      await loadPatients(isRefresh: true);
    }
    return success;
  }

  Future<bool> editPatient(String id, Map<String, dynamic> data) async {
    final success = await _patientService.updatePatient(id, data);
    if (success) {
      await loadPatients(isRefresh: true);
    }
    return success;
  }

  Future<bool> deletePatient(String id) async {
    final success = await _patientService.deletePatient(id);
    if (success) {
      await loadPatients(isRefresh: true);
    }
    return success;
  }

  Future<bool> restorePatient(String id) async {
    final success = await _patientService.restorePatient(id);
    if (success) {
      await loadPatients(isRefresh: true);
    }
    return success;
  }

  void toggleIncludeDeleted() {
    _includeDeleted = !_includeDeleted;
    loadPatients(isRefresh: true);
  }
}