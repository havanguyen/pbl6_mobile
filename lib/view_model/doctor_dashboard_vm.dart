import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/stats/stats.types.dart';
import 'package:pbl6mobile/model/entities/appointment_response.dart';
import 'package:pbl6mobile/model/services/remote/stats_service.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';

class DoctorDashboardVm extends ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();

  DoctorDashboardVm();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  DoctorMyStats? _doctorStats;
  DoctorMyStats? get doctorStats => _doctorStats;

  List<AppointmentData> _pendingAppointments = [];
  List<AppointmentData> get pendingAppointments => _pendingAppointments;
  int _pendingTotal = 0;
  int get pendingTotal => _pendingTotal;

  List<AppointmentData> _upcomingAppointments = [];
  List<AppointmentData> get upcomingAppointments => _upcomingAppointments;
  int _upcomingTotal = 0;
  int get upcomingTotal => _upcomingTotal;

  // Initialize data
  Future<void> initData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _fetchDoctorStats(),
        _fetchPendingAppointments(),
        _fetchUpcomingAppointments(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchDoctorStats() async {
    try {
      final stats = await StatsService.getDoctorMyStats();
      _doctorStats = stats;
    } catch (e) {
      print('Error fetching doctor stats: $e');
    }
  }

  Future<void> _fetchPendingAppointments() async {
    try {
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month - 2, now.day);
      final toDate = DateTime(now.year, now.month + 2, now.day);

      final response = await _appointmentService.getAppointments(
        fromDate: fromDate,
        toDate: toDate,
        status: 'BOOKED', // Pending confirmation
        page: 1,
        limit: 10,
      );

      if (response != null && response.success) {
        _pendingAppointments = response.data;
        _pendingTotal = response.meta?['total'] ?? 0;
      }
    } catch (e) {
      print('Error fetching pending appointments: $e');
    }
  }

  Future<void> _fetchUpcomingAppointments() async {
    try {
      final now = DateTime.now();
      final toDate = now.add(
        const Duration(days: 2),
      ); // Next 2 days + today = 3 days range

      final response = await _appointmentService.getAppointments(
        fromDate: now,
        toDate: toDate,
        status: 'CONFIRMED', // Upcoming
        page: 1,
        limit: 10,
      );

      if (response != null && response.success) {
        _upcomingAppointments = response.data;
        _upcomingTotal = response.meta?['total'] ?? 0;
      }
    } catch (e) {
      print('Error fetching upcoming appointments: $e');
    }
  }
}
