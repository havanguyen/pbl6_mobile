import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/office_hour.dart';
import 'package:pbl6mobile/model/services/remote/office_hour_service.dart';

class OfficeHoursVm extends ChangeNotifier {
  final OfficeHourService _service = OfficeHourService();

  List<OfficeHour> _officeHours = [];
  bool _isLoading = false;
  String? _error;

  List<OfficeHour> get officeHours => _officeHours;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOfficeHours({
    String? doctorId,
    String? workLocationId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.getOfficeHours(
        doctorId: doctorId,
        workLocationId: workLocationId,
      );

      if (result != null) {
        _officeHours = result;
      } else {
        _error = "Không thể tải dữ liệu giờ làm việc";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createOfficeHour({
    String? doctorId,
    String? workLocationId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    bool isGlobal = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.createOfficeHour(
        doctorId: doctorId,
        workLocationId: workLocationId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        isGlobal: isGlobal,
      );

      if (success) {
        await fetchOfficeHours(); // Refresh list
        return true;
      } else {
        _error = "Không thể tạo giờ làm việc";
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteOfficeHour(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _service.deleteOfficeHour(id);

      if (success) {
        await fetchOfficeHours(); // Refresh list
        return true;
      } else {
        _error = "Không thể xóa giờ làm việc";
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
