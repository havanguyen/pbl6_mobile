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

  Future<void> fetchAppointments(DateTime fromDate, DateTime toDate) async {
    await Future.delayed(Duration.zero);

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _appointmentService.getAppointments(
        fromDate: fromDate,
        toDate: toDate,
        status: 'BOOKED',
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
    } else if (appointment.status == 'CANCELLED') {
      return Colors.red;
    }
    return Colors.grey;
  }

  @override
  Object? getId(int index) {
    return (appointments![index] as AppointmentData).id;
  }
}