import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/model/services/local/patient_database_helper.dart';
import 'package:pbl6mobile/model/services/remote/patient_service.dart';

class PatientVm extends ChangeNotifier {
  final PatientService _patientService = PatientService();
  final PatientDatabaseHelper _dbHelper = PatientDatabaseHelper.instance;

  List<Patient> patients = [];
  bool isLoading = false;
  bool isFirstLoad = true;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  String? _error;
  String? get error => _error;

  int _page = 1;
  final int _limit = 10;
  bool _hasNext = true;

  bool _includeDeleted = false;
  bool get includeDeleted => _includeDeleted;

  String _searchQuery = '';
  // ignore: unused_field
  Timer? _debounce; // Keep reference to cancel if needed

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void setSearch(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      loadPatients(isRefresh: true);
    });
  }

  Future<void> loadPatients({bool isRefresh = false}) async {
    if (isLoading || (_isLoadingMore && !isRefresh)) return;

    if (isRefresh) {
      _page = 1;
      _hasNext = true;
      isLoading = true;
    } else if (isFirstLoad) {
      isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      if (!_hasNext && !isRefresh) {
        isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final result = await _patientService.getPatients(
        page: _page,
        limit: _limit,
        includedDeleted: _includeDeleted,
        search: _searchQuery,
      );

      if (_isOffline) {
        _isOffline = false;
      }

      final List<Patient> fetchedPatients = result['patients'] ?? [];
      final meta = result['meta'];

      if (meta != null) {
        _hasNext = meta['hasNext'] ?? false;
      }

      if (isRefresh) {
        patients.clear();
      }

      patients.addAll(fetchedPatients);
      _page++;

      // Only cache if we are not searching and not including deleted items
      if (!_includeDeleted && _searchQuery.isEmpty && patients.isNotEmpty) {
        await _dbHelper.cachePatients(patients);
      }
    } catch (e) {
      if (e is DioException && e.error is SocketException) {
        _isOffline = true;
        debugPrint("Network error: Host lookup failed. App is offline.");
        if ((isFirstLoad || isRefresh) &&
            patients.isEmpty &&
            !_includeDeleted) {
          debugPrint("Loading from cache due to offline status...");
          final cachedPatients = await _dbHelper.getCachedPatients();
          if (cachedPatients.isNotEmpty) {
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              patients = cachedPatients
                  .where(
                    (p) =>
                        p.fullName.toLowerCase().contains(query) ||
                        (p.email?.toLowerCase().contains(query) ?? false) ||
                        (p.phone?.contains(query) ?? false),
                  )
                  .toList();
            } else {
              patients = cachedPatients;
            }
          }
        }
      } else {
        _error = 'fetch_patients_error';
        debugPrint("Error loading patients: $e");
      }
    } finally {
      isLoading = false;
      isFirstLoad = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> addPatient(Map<String, dynamic> data) async {
    if (_isOffline) return false;
    try {
      final success = await _patientService.createPatient(data);
      if (success) {
        await loadPatients(isRefresh: true);
        return true;
      } else {
        _error = 'create_patient_error';
        return false;
      }
    } catch (e) {
      _error = 'create_patient_error';
      debugPrint("Add patient error: $e");
      return false;
    }
  }

  Future<bool> editPatient(String id, Map<String, dynamic> data) async {
    if (_isOffline) return false;
    try {
      final success = await _patientService.updatePatient(id, data);
      if (success) {
        final updatedPatient = await _patientService.getPatientById(id);
        if (updatedPatient != null) {
          final index = patients.indexWhere((p) => p.id == id);
          if (index != -1) {
            patients[index] = updatedPatient;
            notifyListeners();
          } else {
            await loadPatients(isRefresh: true);
          }
        } else {
          await loadPatients(isRefresh: true);
        }
        return true;
      } else {
        _error = 'update_patient_error';
        return false;
      }
    } catch (e) {
      _error = 'update_patient_error';
      debugPrint("Edit patient error: $e");
      return false;
    }
  }

  Future<bool> deletePatient(String id) async {
    if (_isOffline) return false;
    try {
      final success = await _patientService.deletePatient(id);
      if (success) {
        if (_includeDeleted) {
          final index = patients.indexWhere((p) => p.id == id);
          if (index != -1) {
            final updatedPatient = await _patientService.getPatientById(id);
            if (updatedPatient != null) {
              patients[index] = updatedPatient;
              notifyListeners();
            } else {
              await loadPatients(isRefresh: true);
            }
          }
        } else {
          patients.removeWhere((p) => p.id == id);
          if (_searchQuery.isEmpty && !_includeDeleted) {
            await _dbHelper.cachePatients(patients);
          }
          notifyListeners();
        }
        return true;
      } else {
        _error = 'delete_patient_error';
        return false;
      }
    } catch (e) {
      _error = 'delete_patient_error';
      debugPrint("Delete patient error: $e");
      return false;
    }
  }

  Future<bool> restorePatient(String id) async {
    if (_isOffline) return false;
    try {
      final success = await _patientService.restorePatient(id);
      if (success) {
        final index = patients.indexWhere((p) => p.id == id);
        if (index != -1) {
          final updatedPatient = await _patientService.getPatientById(id);
          if (updatedPatient != null) {
            patients[index] = updatedPatient;
            notifyListeners();
          }
        }
        if (!_includeDeleted) {
          patients.removeWhere((p) => p.id == id);
          notifyListeners();
        }
        return true;
      } else {
        _error = 'restore_patient_error';
        return false;
      }
    } catch (e) {
      _error = 'restore_patient_error';
      debugPrint("Restore patient error: $e");
      return false;
    }
  }

  void toggleIncludeDeleted() {
    _includeDeleted = !_includeDeleted;
    if (_includeDeleted) {
      _dbHelper.clearPatients();
    }
    loadPatients(isRefresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
