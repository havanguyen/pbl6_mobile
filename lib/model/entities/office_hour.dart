import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';

class OfficeHour {
  final String id;
  final String? doctorId;
  final String? workLocationId;
  final int dayOfWeek; // 0-6 (0 = Sunday, 1 = Monday, ..., 6 = Saturday)
  final String startTime; // HH:mm format
  final String endTime; // HH:mm format
  final bool isGlobal;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Expanded relations (optional)
  final Doctor? doctor;
  final WorkLocation? workLocation;

  OfficeHour({
    required this.id,
    this.doctorId,
    this.workLocationId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isGlobal,
    required this.createdAt,
    required this.updatedAt,
    this.doctor,
    this.workLocation,
  });

  factory OfficeHour.fromJson(Map<String, dynamic> json) {
    return OfficeHour(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String?,
      workLocationId: json['workLocationId'] as String?,
      dayOfWeek: json['dayOfWeek'] as int,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      isGlobal: json['isGlobal'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      doctor: json['doctor'] != null
          ? Doctor.fromJson(json['doctor'] as Map<String, dynamic>)
          : null,
      workLocation: json['workLocation'] != null
          ? WorkLocation.fromJson(json['workLocation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorId': doctorId,
    'workLocationId': workLocationId,
    'dayOfWeek': dayOfWeek,
    'startTime': startTime,
    'endTime': endTime,
    'isGlobal': isGlobal,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'doctor': doctor?.toJson(),
    'workLocation': workLocation?.toJson(),
  };
}
