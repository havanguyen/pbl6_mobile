import 'package:json_annotation/json_annotation.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';

part 'appointment_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class AppointmentResponse {
  final bool success;
  final List<AppointmentData> data;
  final Map<String, dynamic>? meta;

  AppointmentResponse({
    required this.success,
    required this.data,
    this.meta,
  });

  factory AppointmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AppointmentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentResponseToJson(this);
}