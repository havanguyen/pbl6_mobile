import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';

class AppointmentVm extends ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();

  List<AppointmentData> _appointments = [];
  bool _isLoading = false;
  String? _error;

  // Map to track loading state for specific appointment actions (key: appointmentId)
  final Map<String, bool> _actionLoading = {};
  String? _actionError;

  List<AppointmentData> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get actionError => _actionError;

  AppointmentDataSource _dataSource = AppointmentDataSource([]);
  AppointmentDataSource get dataSource => _dataSource;

  DateTime? _lastFromDate;
  DateTime? _lastToDate;
  String? _lastDoctorId;
  String? _lastWorkLocationId;
  String? _lastSpecialtyId;
  String? _lastPatientId;

  List<AppointmentData> _allAppointmentsCache = [];

  // Calendar Settings
  double _startHour = 7;
  double _endHour = 18;
  Map<int, bool> _workingDays = {
    DateTime.monday: true,
    DateTime.tuesday: true,
    DateTime.wednesday: true,
    DateTime.thursday: true,
    DateTime.friday: true,
    DateTime.saturday: false,
    DateTime.sunday: false,
  };
  String _badgeVariant = 'colored'; // 'colored', 'dot', 'mixed'

  double get startHour => _startHour;
  double get endHour => _endHour;
  Map<int, bool> get workingDays => _workingDays;
  String get badgeVariant => _badgeVariant;

  void updateCalendarSettings({
    double? startHour,
    double? endHour,
    Map<int, bool>? workingDays,
    String? badgeVariant,
  }) {
    if (startHour != null) _startHour = startHour;
    if (endHour != null) _endHour = endHour;
    if (workingDays != null) _workingDays = workingDays;
    if (badgeVariant != null) _badgeVariant = badgeVariant;
    notifyListeners();
  }

  bool isActionLoading(String appointmentId) =>
      _actionLoading[appointmentId] ?? false;

  void _setActionLoading(String appointmentId, bool loading) {
    if (loading) {
      _actionLoading[appointmentId] = true;
    } else {
      _actionLoading.remove(appointmentId);
    }
    notifyListeners();
  }

  Future<void> fetchAppointments(
    DateTime fromDate,
    DateTime toDate, {
    String? doctorId,
    String? workLocationId,
    String? specialtyId,
    String? patientId,
    bool forceRefresh = false,
  }) async {
    print('--- [DEBUG] AppointmentVm.fetchAppointments ---');
    print('fromDate: $fromDate, toDate: $toDate');

    if (_isLoading) return;

    _lastDoctorId = doctorId;
    _lastWorkLocationId = workLocationId;
    _lastSpecialtyId = specialtyId;
    _lastPatientId = patientId;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<AppointmentData> allAppointments = [];

      // Check Cache
      if (!forceRefresh &&
          _lastFromDate != null &&
          _lastToDate != null &&
          _lastFromDate == fromDate &&
          _lastToDate == toDate &&
          _allAppointmentsCache.isNotEmpty) {
        allAppointments = List.from(_allAppointmentsCache);
      } else {
        // Fetch from API
        int currentPage = 1;
        bool hasNext = true;

        while (hasNext) {
          final response = await _appointmentService.getAppointments(
            fromDate: fromDate,
            toDate: toDate,
            doctorId: null,
            workLocationId: null,
            specialtyId: null,
            patientId: null,
            limit: 100, // Respect API limit
            page: currentPage,
          );

          if (response != null && response.success) {
            allAppointments.addAll(response.data);

            final meta = response.meta;
            if (meta != null && meta['hasNext'] == true) {
              currentPage++;
            } else {
              hasNext = false;
            }
          } else {
            _error = response?.message ?? 'Failed to fetch appointments';
            hasNext = false; // Stop on error
          }
        }

        // Update Cache if successful
        if (_error == null) {
          _allAppointmentsCache = List.from(allAppointments);
          _lastFromDate = fromDate;
          _lastToDate = toDate;
        }
      }

      // Update state only if we fetched something or it was a successful empty result
      if (_error == null) {
        // Apply Filters LOCALLY
        var filteredList = allAppointments;

        if (doctorId != null) {
          filteredList = filteredList
              .where(
                (appt) =>
                    appt.doctorId == doctorId || appt.doctor.id == doctorId,
              )
              .toList();
        }
        if (workLocationId != null) {
          filteredList = filteredList
              .where((appt) => appt.locationId == workLocationId)
              .toList();
        }
        if (specialtyId != null) {
          filteredList = filteredList
              .where((appt) => appt.specialtyId == specialtyId)
              .toList();
        }
        if (patientId != null) {
          filteredList = filteredList
              .where((appt) => appt.patientId == patientId)
              .toList();
        }

        _appointments = filteredList;
        _dataSource.appointments = List.from(_appointments);
        _dataSource.notifyListeners(
          CalendarDataSourceAction.reset,
          _dataSource.appointments!,
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Removed _syncAppointments, _loadFromCache as we are now using direct fetch on demand.

  Future<void> refresh() async {
    if (_lastFromDate != null && _lastToDate != null) {
      await fetchAppointments(
        _lastFromDate!,
        _lastToDate!,
        doctorId: _lastDoctorId,
        workLocationId: _lastWorkLocationId,
        specialtyId: _lastSpecialtyId,
        patientId: _lastPatientId,
        forceRefresh: true,
      );
    }
  }

  Future<bool> cancelAppointment(String id, String reason) async {
    _setActionLoading(id, true);
    _actionError = null;
    try {
      final success = await _appointmentService.cancelAppointment(id, reason);
      if (success) {
        await refresh();
        return true;
      } else {
        _actionError = "Không thể hủy lịch hẹn";
        return false;
      }
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _setActionLoading(id, false);
    }
  }

  Future<bool> rescheduleAppointment(
    String appointmentId,
    String timeStart,
    String timeEnd,
    DateTime serviceDate, {
    String? doctorId,
    String? locationId,
  }) async {
    _setActionLoading(appointmentId, true);
    _actionError = null;
    notifyListeners();

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(serviceDate);
      final success = await _appointmentService.rescheduleAppointment(
        appointmentId,
        timeStart,
        timeEnd,
        formattedDate,
        doctorId: doctorId,
        locationId: locationId,
      );

      if (success) {
        await refresh();
        return true;
      } else {
        _actionError = 'Failed to reschedule';
        return false;
      }
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _setActionLoading(appointmentId, false);
      notifyListeners();
    }
  }

  Future<bool> completeAppointment(String id) async {
    _setActionLoading(id, true);
    _actionError = null;
    try {
      final success = await _appointmentService.completeAppointment(id);
      if (success) {
        await refresh();
        return true;
      } else {
        _actionError = "Không thể hoàn thành lịch hẹn";
        return false;
      }
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _setActionLoading(id, false);
    }
  }

  Future<bool> confirmAppointment(String id) async {
    _setActionLoading(id, true);
    _actionError = null;
    try {
      final success = await _appointmentService.confirmAppointment(id);
      if (success) {
        await refresh();
        return true;
      } else {
        _actionError = "Không thể xác nhận lịch hẹn";
        return false;
      }
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _setActionLoading(id, false);
    }
  }

  Future<bool> updateAppointment(
    String id,
    String notes,
    double price,
    String currency,
    String status,
    String reason,
  ) async {
    _setActionLoading(id, true);
    _actionError = null;
    try {
      final success = await _appointmentService.updateAppointment(
        id,
        notes,
        price,
        currency,
        status,
        reason,
      );
      if (success) {
        await refresh();
        return true;
      } else {
        _actionError = "Không thể cập nhật lịch hẹn";
        return false;
      }
    } catch (e) {
      _actionError = e.toString();
      return false;
    } finally {
      _setActionLoading(id, false);
    }
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<AppointmentData> source) {
    appointments = List.from(source);
    print('--- [DEBUG] AppointmentDataSource Created ---');
    print('Source count: ${source.length}');
    print('DataSource appointments count: ${appointments?.length}');
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as AppointmentData).appointmentStartTime;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as AppointmentData).appointmentEndTime;
  }

  @override
  String getSubject(int index) {
    final appointment = appointments![index] as AppointmentData;
    return 'BN: ${appointment.patient.fullName}\nBS: ${appointment.doctor.name ?? 'N/A'}';
  }

  @override
  Color getColor(int index) {
    final appointment = appointments![index] as AppointmentData;
    if (appointment.status == 'BOOKED') {
      return Colors.blue;
    } else if (appointment.status == 'COMPLETED') {
      return Colors.green;
    } else if (appointment.status == 'CANCELLED' ||
        appointment.status == 'CANCELLED_BY_STAFF' ||
        appointment.status == 'CANCELLED_BY_PATIENT') {
      return Colors.red;
    } else if (appointment.status == 'RESCHEDULED') {
      return Colors.orange;
    }
    return Colors.grey;
  }

  @override
  Object? getId(int index) {
    return (appointments![index] as AppointmentData).id;
  }
}
