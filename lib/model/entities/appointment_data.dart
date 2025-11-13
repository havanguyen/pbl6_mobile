import 'package:json_annotation/json_annotation.dart';

part 'appointment_data.g.dart';

@JsonSerializable()
class AppointmentPatient {
  final String fullName;
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime? dateOfBirth;

  AppointmentPatient({required this.fullName, this.dateOfBirth});

  factory AppointmentPatient.fromJson(Map<String, dynamic> json) =>
      _$AppointmentPatientFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentPatientToJson(this);
}

@JsonSerializable()
class AppointmentEvent {
  final String id;
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime? serviceDate;
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime? timeStart;
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime? timeEnd;

  AppointmentEvent({
    required this.id,
    this.serviceDate,
    this.timeStart,
    this.timeEnd,
  });

  factory AppointmentEvent.fromJson(Map<String, dynamic> json) =>
      _$AppointmentEventFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentEventToJson(this);
}

@JsonSerializable()
class AppointmentDoctor {
  final String id;
  final String? name;
  final String? avatarUrl;

  AppointmentDoctor({required this.id, this.name, this.avatarUrl});

  factory AppointmentDoctor.fromJson(Map<String, dynamic> json) =>
      _$AppointmentDoctorFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentDoctorToJson(this);
}

@JsonSerializable()
class AppointmentData {
  final String id;
  final String patientId;
  final String doctorId;
  final String? locationId;
  final String eventId;
  final String? specialtyId;
  final String status;
  final String? reason;
  final double? priceAmount;
  final String? currency;
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime? createdAt;

  final AppointmentPatient patient;
  final AppointmentEvent event;
  final AppointmentDoctor doctor;

  AppointmentData({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.locationId,
    required this.eventId,
    this.specialtyId,
    required this.status,
    this.reason,
    this.priceAmount,
    this.currency,
    this.createdAt,
    required this.patient,
    required this.event,
    required this.doctor,
  });

  factory AppointmentData.fromJson(Map<String, dynamic> json) =>
      _$AppointmentDataFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentDataToJson(this);

  DateTime get appointmentStartTime {
    if (event.serviceDate == null || event.timeStart == null) {
      return DateTime.now();
    }
    return DateTime(
      event.serviceDate!.year,
      event.serviceDate!.month,
      event.serviceDate!.day,
      event.timeStart!.hour,
      event.timeStart!.minute,
    );
  }

  DateTime get appointmentEndTime {
    if (event.serviceDate == null || event.timeEnd == null) {
      return DateTime.now().add(const Duration(minutes: 30));
    }
    return DateTime(
      event.serviceDate!.year,
      event.serviceDate!.month,
      event.serviceDate!.day,
      event.timeEnd!.hour,
      event.timeEnd!.minute,
    );
  }
}

DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null || value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}