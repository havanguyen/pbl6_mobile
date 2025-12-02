import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';

class PatientService {
  final Dio _dio = AuthService.getSecureDioInstance();

  Future<Map<String, dynamic>> getPatients({
    int page = 1,
    int limit = 10,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool includedDeleted = false,
    String? search,
  }) async {
    final response = await _dio.get(
      '/patients',
      queryParameters: {
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'includedDeleted': includedDeleted,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data['data'] as List;
      final meta = response.data['meta'];
      final patients = data.map((json) => Patient.fromJson(json)).toList();
      return {'patients': patients, 'meta': meta};
    }
    return {'patients': <Patient>[], 'meta': null};
  }

  Future<Patient?> getPatientById(String id) async {
    try {
      final response = await _dio.get('/patients/$id');
      if (response.statusCode == 200) {
        return Patient.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print("Get patient by ID error: $e");
      return null;
    }
  }

  Future<bool> createPatient(Map<String, dynamic> patientData) async {
    try {
      final response = await _dio.post('/patients', data: patientData);
      return response.statusCode == 201;
    } catch (e) {
      print("Create patient error: $e");
      return false;
    }
  }

  Future<bool> updatePatient(
    String id,
    Map<String, dynamic> patientData,
  ) async {
    try {
      final response = await _dio.patch('/patients/$id', data: patientData);
      return response.statusCode == 200;
    } catch (e) {
      print("Update patient error: $e");
      return false;
    }
  }

  Future<bool> deletePatient(String id) async {
    try {
      final response = await _dio.delete('/patients/$id');
      return response.statusCode == 200;
    } catch (e) {
      print("Delete patient error: $e");
      return false;
    }
  }

  Future<bool> restorePatient(String id) async {
    try {
      final response = await _dio.patch('/patients/$id/restore');
      return response.statusCode == 200;
    } catch (e) {
      print("Restore patient error: $e");
      return false;
    }
  }
}
