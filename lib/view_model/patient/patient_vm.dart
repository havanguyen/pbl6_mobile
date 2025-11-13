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
      isLoading = true;
    } else if (isFirstLoad) {
      isLoading = true;
    } else {
      _isLoadingMore = true;
    }
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
      );

      if (_isOffline) {
        _isOffline = false;
      }

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

      if (!_includeDeleted && patients.isNotEmpty) {
        await _dbHelper.cachePatients(patients);
      }
    } catch (e) {
      if (e is DioException && e.error is SocketException) {
        _isOffline = true;
        print("Network error: Host lookup failed. App is offline.");
        if ((isFirstLoad || isRefresh) && patients.isEmpty && !_includeDeleted) {
          print("Loading from cache due to offline status...");
          final cachedPatients = await _dbHelper.getCachedPatients();
          if (cachedPatients.isNotEmpty) {
            patients = cachedPatients;
          }
        }
      } else {
        print("Error loading patients: $e");
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
    final success = await _patientService.createPatient(data);
    if (success) {
      await loadPatients(isRefresh: true);
    }
    return success;
  }

  Future<bool> editPatient(String id, Map<String, dynamic> data) async {
    if (_isOffline) return false;
    final success = await _patientService.updatePatient(id, data);
    if (success) {
      final updatedPatient = await _patientService.getPatientById(id);
      if (updatedPatient != null) {
        final index = patients.indexWhere((p) => p.id == id);
        if (index != -1) {
          patients[index] = updatedPatient;
          if (!_includeDeleted) {
            await _dbHelper.cachePatients(patients);
          }
          notifyListeners();
        } else {
          await loadPatients(isRefresh: true);
        }
      } else {
        await loadPatients(isRefresh: true);
      }
    }
    return success;
  }

  Future<bool> deletePatient(String id) async {
    if (_isOffline) return false;
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
        } else {
          await loadPatients(isRefresh: true);
        }
      } else {
        patients.removeWhere((p) => p.id == id);
        await _dbHelper.cachePatients(patients);
        notifyListeners();
      }
    }
    return success;
  }

  Future<bool> restorePatient(String id) async {
    if (_isOffline) return false;
    final success = await _patientService.restorePatient(id);
    if (success) {
      final index = patients.indexWhere((p) => p.id == id);
      if (index != -1) {
        final updatedPatient = await _patientService.getPatientById(id);
        if (updatedPatient != null) {
          patients[index] = updatedPatient;
          notifyListeners();
        } else {
          await loadPatients(isRefresh: true);
        }
      } else {
        await loadPatients(isRefresh: true);
      }
    }
    return success;
  }

  void toggleIncludeDeleted() {
    _includeDeleted = !_includeDeleted;
    if (_includeDeleted) {
      _dbHelper.clearPatients();
    }
    loadPatients(isRefresh: true);
  }
}