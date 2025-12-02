import 'package:pbl6mobile/model/entities/appointment_data.dart';

class AppointmentResponse {
  final bool success;
  final List<AppointmentData> data;
  final Map<String, dynamic>? meta;

  AppointmentResponse({required this.success, required this.data, this.meta});

  factory AppointmentResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentResponse(
      success: json['success'] as bool? ?? false,
      data:
          (json['data'] as List<dynamic>?)
              ?.map((e) => AppointmentData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data.map((e) => e.toJson()).toList(),
      'meta': meta,
    };
  }
}
