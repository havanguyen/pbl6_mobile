import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/entities/office_hour.dart';
import 'package:pbl6mobile/model/services/remote/office_hour_service.dart';

class OfficeHoursVm extends ChangeNotifier {
  final OfficeHourService _service = OfficeHourService();

  List<OfficeHour> _officeHours = [];
  bool _isLoading = false;
  String? _error;

  bool _isOffline = false;

  List<OfficeHour> get officeHours => _officeHours;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String _handleDioError(DioException e, String contextMessage) {
    _isOffline =
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown ||
        (e.message ?? '').contains('Failed host lookup');

    if (_isOffline) {
      return 'Lỗi kết nối mạng. Vui lòng kiểm tra lại.';
    } else if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      String? apiMessage;

      if (data is Map) {
        apiMessage = data['message'] ?? data['error'];
      }

      if (statusCode == 404) {
        if ((apiMessage ?? '').contains('Doctor'))
          return 'Bác sĩ đã chọn không tồn tại.';
        if ((apiMessage ?? '').contains('WorkLocation'))
          return 'Cơ sở làm việc đã chọn không tồn tại.';
        return apiMessage ?? 'Không tìm thấy dữ liệu yêu cầu.';
      }

      if (statusCode == 400) {
        return apiMessage ?? 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
      }

      return '$contextMessage: ${apiMessage ?? e.message} (Code: $statusCode)';
    } else {
      return '$contextMessage: ${e.message}';
    }
  }

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
        _error = 'fetch_office_hours_failed';
      }
    } on DioException catch (e) {
      _error = _handleDioError(e, "Lỗi tải lịch làm việc");
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
    _error = null;
    notifyListeners();

    try {
      final createdOfficeHour = await _service.createOfficeHour(
        doctorId: doctorId,
        workLocationId: workLocationId,
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        isGlobal: isGlobal,
      );

      if (createdOfficeHour != null) {
        await fetchOfficeHours(); // Refresh list
        return true;
      } else {
        _error = 'create_office_hour_failed';
        return false;
      }
    } on DioException catch (e) {
      _error = _handleDioError(e, "Lỗi tạo lịch làm việc");
      return false;
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
    _error = null;
    notifyListeners();

    try {
      final success = await _service.deleteOfficeHour(id);

      if (success) {
        await fetchOfficeHours(); // Refresh list
        return true;
      } else {
        _error = 'delete_office_hour_failed';
        return false;
      }
    } on DioException catch (e) {
      _error = _handleDioError(e, "Lỗi xóa lịch làm việc");
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
