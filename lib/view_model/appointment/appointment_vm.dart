import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AppointmentVm extends ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();

  List<AppointmentData> _appointments = [];
  bool _isLoading = false;
  String? _error;

  List<AppointmentData> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AppointmentDataSource? _dataSource;
  AppointmentDataSource? get dataSource => _dataSource;

  DateTime? _lastFromDate;
  DateTime? _lastToDate;

  Future<void> fetchAppointments(DateTime fromDate, DateTime toDate) async {
    await Future.delayed(Duration.zero);

    if (_isLoading) return;

    _lastFromDate = fromDate;
    _lastToDate = toDate;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _appointmentService.getAppointments(
        fromDate: fromDate,
        toDate: toDate,
        // status: 'BOOKED', // Show all statuses
      );
      if (response != null && response.success) {
        _appointments = response.data;
        _dataSource = AppointmentDataSource(_appointments);
      } else {
        _error = "Không thể tải dữ liệu lịch hẹn";
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_lastFromDate != null && _lastToDate != null) {
      await fetchAppointments(_lastFromDate!, _lastToDate!);
    }
  }

  Future<bool> cancelAppointment(String id, String reason) async {
    final success = await _appointmentService.cancelAppointment(id, reason);
    if (success) await refresh();
    return success;
  }

  Future<bool> rescheduleAppointment(String id, String timeStart, String timeEnd) async {
    final success = await _appointmentService.rescheduleAppointment(id, timeStart, timeEnd);
    if (success) await refresh();
    return success;
  }

  Future<bool> completeAppointment(String id) async {
    final success = await _appointmentService.completeAppointment(id);
    if (success) await refresh();
    return success;
  }

  Future<bool> confirmAppointment(String id) async {
    final success = await _appointmentService.confirmAppointment(id);
    if (success) await refresh();
    return success;
  }

  Future<bool> updateAppointment(String id, String notes, double price, String currency) async {
    final success = await _appointmentService.updateAppointment(id, notes, price, currency);
    if (success) await refresh();
    return success;
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<AppointmentData> source) {
    appointments = source;
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
    } else if (appointment.status == 'CANCELLED' || appointment.status == 'CANCELLED_BY_STAFF' || appointment.status == 'CANCELLED_BY_PATIENT') {
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