import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';
import 'package:pbl6mobile/model/services/local/appointment_database_helper.dart';
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
    print(
      'Filters: doctorId=$doctorId, locationId=$workLocationId, specialtyId=$specialtyId, forceRefresh=$forceRefresh',
    );
    await Future.delayed(Duration.zero);

    if (_isLoading) return;

    _lastFromDate = fromDate;
    _lastToDate = toDate;
    _lastDoctorId = doctorId;
    _lastWorkLocationId = workLocationId;
    _lastSpecialtyId = specialtyId;
    _lastPatientId = patientId;

    _isLoading = true;
    _error = null;
    notifyListeners();

    // New Logic: API (Sync) -> Local DB -> Memory/UI
    // 1. Load from cache immediately
    await _loadFromCache(fromDate, toDate, doctorId: doctorId);

    // 2. If forced or not synced, sync data
    if (forceRefresh || !_isSynced) {
      if (forceRefresh) {
        print(
          '--- [DEBUG] Force refresh requested. Resetting sync status. ---',
        );
        _isSynced = false;
      }
      // Run sync in background, don't await to block UI
      _syncAppointments();
    }

    _isLoading = false;
    notifyListeners();
  }

  bool _isSynced = false;

  Future<void> _syncAppointments() async {
    print(
      '--- [DEBUG] AppointmentVm: Starting background sync of ALL pages (2 years range) ---',
    );
    final now = DateTime.now();
    final syncFrom = DateTime(now.year - 2, now.month, now.day);
    final syncTo = DateTime(now.year + 2, now.month, now.day);

    int currentPage = 1;
    bool hasNext = true;
    List<AppointmentData> allSyncedAppointments = [];

    try {
      while (hasNext) {
        print('--- [DEBUG] Fetching page $currentPage ---');
        final response = await _appointmentService.getAppointments(
          fromDate: syncFrom,
          toDate: syncTo,
          doctorId: _lastDoctorId,
          workLocationId: _lastWorkLocationId,
          specialtyId: _lastSpecialtyId,
          patientId: _lastPatientId,
          limit: 100,
          page: currentPage,
        );

        if (response != null && response.success) {
          if (response.data.isNotEmpty) {
            allSyncedAppointments.addAll(response.data);
          }

          final meta = response.meta;
          if (meta != null && meta['hasNext'] == true) {
            currentPage++;
          } else {
            hasNext = false;
          }
        } else {
          print('--- [ERROR] Sync failed at page $currentPage. Stopping. ---');
          hasNext = false;
        }
      }

      print(
        '--- [DEBUG] AppointmentVm: Sync complete. Total fetched: ${allSyncedAppointments.length} ---',
      );

      // CLEAR cache for the synced range first
      await AppointmentDatabaseHelper.instance.deleteAppointmentsInRange(
        fromDate: syncFrom,
        toDate: syncTo,
      );

      // THEN insert new data
      if (allSyncedAppointments.isNotEmpty) {
        await AppointmentDatabaseHelper.instance.insertAppointments(
          allSyncedAppointments,
        );
      }

      _isSynced = true;

      if (_lastFromDate != null && _lastToDate != null) {
        await _loadFromCache(
          _lastFromDate!,
          _lastToDate!,
          doctorId: _lastDoctorId,
        );
      }
    } catch (e) {
      print('--- [ERROR] AppointmentVm: Sync error: $e ---');
    }
  }

  Future<void> _loadFromCache(
    DateTime fromDate,
    DateTime toDate, {
    String? doctorId,
  }) async {
    print('--- [DEBUG] AppointmentVm: Loading from cache... ---');
    print('--- [DEBUG] _loadFromCache: doctorId=$doctorId ---');
    try {
      final cachedAppointments = await AppointmentDatabaseHelper.instance
          .getAppointments(
            fromDate: fromDate,
            toDate: toDate,
            doctorId: doctorId,
          );
      if (cachedAppointments.isNotEmpty) {
        _appointments = cachedAppointments.toSet().toList();
        print(
          '--- [DEBUG] Loaded ${_appointments.length} unique appointments (original: ${cachedAppointments.length}) ---',
        );
        _dataSource.appointments = List.from(_appointments);
        _dataSource.notifyListeners(
          CalendarDataSourceAction.reset,
          _dataSource.appointments!,
        );
        print(
          '--- [DEBUG] AppointmentVm: Loaded ${cachedAppointments.length} appointments from cache ---',
        );
        // If we successfully loaded from cache, we can clear the error or show a specific "Offline" message
        // For now, let's append to the error so the user knows they are offline but seeing cached data
        _error = "${_error ?? 'Lỗi kết nối'}. Đang hiển thị dữ liệu offline.";
      } else {
        print(
          '--- [DEBUG] AppointmentVm: No cached appointments found for this range ---',
        );
      }
    } catch (e) {
      print('--- [ERROR] AppointmentVm: Failed to load from cache: $e ---');
    }
  }

  Future<void> refresh() async {
    print(
      '--- [DEBUG] AppointmentVm: Force Refresh - Clearing all local data ---',
    );
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Clear memory immediately to avoid showing old data
      _appointments = [];
      _dataSource.appointments = [];
      _dataSource.notifyListeners(CalendarDataSourceAction.reset, []);

      // 2. Clear DB (Full invalidation as requested)
      await AppointmentDatabaseHelper.instance.clearAll();

      // 3. Reset sync status
      _isSynced = false;

      // 4. Re-fetch data
      await _syncAppointments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
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
