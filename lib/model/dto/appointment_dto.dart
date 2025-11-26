import 'package:json_annotation/json_annotation.dart';

part 'appointment_dto.g.dart';

@JsonSerializable()
class DoctorSlot {
  final String timeStart;
  final String timeEnd;
  final bool? isAvailable;

  DoctorSlot({
    required this.timeStart,
    required this.timeEnd,
    this.isAvailable,
  });

  factory DoctorSlot.fromJson(Map<String, dynamic> json) => _$DoctorSlotFromJson(json);
  Map<String, dynamic> toJson() => _$DoctorSlotToJson(this);
}

@JsonSerializable()
class HoldAppointmentRequest {
  final String doctorId;
  final String locationId;
  final String serviceDate;
  final String timeStart;
  final String timeEnd;

  HoldAppointmentRequest({
    required this.doctorId,
    required this.locationId,
    required this.serviceDate,
    required this.timeStart,
    required this.timeEnd,
  });

  Map<String, dynamic> toJson() => _$HoldAppointmentRequestToJson(this);
}

@JsonSerializable()
class CreateAppointmentRequest {
  final String? eventId;
  final String? serviceDate;
  final String? timeStart;
  final String? timeEnd;
  final String? locationId;
  final String? doctorId;
  final String patientId;
  final String specialtyId;
  final String? reason;
  final String? notes;
  final double? priceAmount;
  final String? currency;

  CreateAppointmentRequest({
    this.eventId,
    this.serviceDate,
    this.timeStart,
    this.timeEnd,
    this.locationId,
    this.doctorId,
    required this.patientId,
    required this.specialtyId,
    this.reason,
    this.notes,
    this.priceAmount,
    this.currency,
  });

  Map<String, dynamic> toJson() => _$CreateAppointmentRequestToJson(this);
}