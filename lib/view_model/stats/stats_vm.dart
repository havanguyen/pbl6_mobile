import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/stats/stats.types.dart';
import 'package:pbl6mobile/model/services/remote/stats_service.dart';

class StatsVm extends ChangeNotifier {
  StaffStats? _staffStats;
  List<RevenueStats> _revenueStats = [];
  List<RevenueByDoctorStats> _revenueByDoctorStats = [];
  PatientStats? _patientStats;
  AppointmentStats? _appointmentStats;
  ReviewsOverviewStats? _reviewsStats;
  QAOverviewStats? _qaStats;

  bool _isLoadingStaff = false;
  bool _isLoadingRevenue = false;
  bool _isLoadingTopDoctors = false;
  bool _isLoadingPatients = false;
  bool _isLoadingAppointments = false;
  bool _isLoadingReviews = false;
  bool _isLoadingQA = false;

  String? _error;

  // Getters
  StaffStats? get staffStats => _staffStats;
  List<RevenueStats> get revenueStats => _revenueStats;
  List<RevenueByDoctorStats> get revenueByDoctorStats => _revenueByDoctorStats;
  PatientStats? get patientStats => _patientStats;
  AppointmentStats? get appointmentStats => _appointmentStats;
  ReviewsOverviewStats? get reviewsStats => _reviewsStats;
  QAOverviewStats? get qaStats => _qaStats;

  bool get isLoadingStaff => _isLoadingStaff;
  bool get isLoadingRevenue => _isLoadingRevenue;
  bool get isLoadingTopDoctors => _isLoadingTopDoctors;
  bool get isLoadingPatients => _isLoadingPatients;
  bool get isLoadingAppointments => _isLoadingAppointments;
  bool get isLoadingReviews => _isLoadingReviews;
  bool get isLoadingQA => _isLoadingQA;

  bool get isLoadingAny =>
      _isLoadingStaff ||
      _isLoadingRevenue ||
      _isLoadingTopDoctors ||
      _isLoadingPatients ||
      _isLoadingAppointments ||
      _isLoadingReviews ||
      _isLoadingQA;

  String? get error => _error;

  double get totalRevenue {
    return _revenueStats.fold(0.0, (sum, item) {
      // 'VND' is the key.
      return sum + (item.total['VND'] ?? 0);
    });
  }

  double get avgRevenuePerPatient {
    final patients = _patientStats?.totalPatients ?? 0;
    if (patients == 0) return 0;
    return totalRevenue / patients;
  }

  double get avgRevenuePerAppointment {
    final appointments = _appointmentStats?.totalAppointments ?? 0;
    if (appointments == 0) return 0;
    return totalRevenue / appointments;
  }

  Future<void> refreshAll({bool force = false}) async {
    _error = null;
    notifyListeners();

    // Fire all requests concurrently
    await Future.wait([
      fetchStaffStats(),
      fetchRevenueStats(),
      fetchRevenueByDoctorStats(),
      fetchPatientStats(),
      fetchAppointmentStats(),
      fetchReviewsStats(),
      fetchQAStats(),
    ]);
  }

  Future<void> fetchStaffStats() async {
    _isLoadingStaff = true;
    notifyListeners();
    try {
      _staffStats = await StatsService.getStaffStats();
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoadingStaff = false;
      notifyListeners();
    }
  }

  Future<void> fetchRevenueStats() async {
    _isLoadingRevenue = true;
    notifyListeners();
    try {
      _revenueStats = await StatsService.getRevenueStats();
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoadingRevenue = false;
      notifyListeners();
    }
  }

  Future<void> fetchRevenueByDoctorStats() async {
    _isLoadingTopDoctors = true;
    notifyListeners();
    try {
      _revenueByDoctorStats = await StatsService.getRevenueByDoctorStats();
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoadingTopDoctors = false;
      notifyListeners();
    }
  }

  Future<void> fetchPatientStats() async {
    _isLoadingPatients = true;
    notifyListeners();
    try {
      _patientStats = await StatsService.getPatientStats();
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoadingPatients = false;
      notifyListeners();
    }
  }

  Future<void> fetchAppointmentStats() async {
    _isLoadingAppointments = true;
    notifyListeners();
    try {
      _appointmentStats = await StatsService.getAppointmentStats();
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoadingAppointments = false;
      notifyListeners();
    }
  }

  void _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        _error = e.response?.data['message'] ?? 'Unable to fetch data';
      } else {
        _error = 'Connection error';
      }
    } else {
      _error = e.toString();
    }
    // Note: We might want not to overwrite error if multiple fail
    debugPrint("StatsVm Error: $e");
  }

  Future<void> fetchReviewsStats() async {
    _isLoadingReviews = true;
    notifyListeners();
    try {
      _reviewsStats = await StatsService.getReviewsOverviewStats();
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoadingReviews = false;
      notifyListeners();
    }
  }

  Future<void> fetchQAStats() async {
    _isLoadingQA = true;
    notifyListeners();
    try {
      _qaStats = await StatsService.getQAOverviewStats();
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoadingQA = false;
      notifyListeners();
    }
  }
}
