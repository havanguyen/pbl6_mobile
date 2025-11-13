// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppointmentPatient _$AppointmentPatientFromJson(Map<String, dynamic> json) =>
    AppointmentPatient(
      fullName: json['fullName'] as String,
      dateOfBirth: _dateTimeFromJson(json['dateOfBirth']),
    );

Map<String, dynamic> _$AppointmentPatientToJson(AppointmentPatient instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
    };

AppointmentEvent _$AppointmentEventFromJson(Map<String, dynamic> json) =>
    AppointmentEvent(
      id: json['id'] as String,
      serviceDate: _dateTimeFromJson(json['serviceDate']),
      timeStart: _dateTimeFromJson(json['timeStart']),
      timeEnd: _dateTimeFromJson(json['timeEnd']),
    );

Map<String, dynamic> _$AppointmentEventToJson(AppointmentEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'serviceDate': instance.serviceDate?.toIso8601String(),
      'timeStart': instance.timeStart?.toIso8601String(),
      'timeEnd': instance.timeEnd?.toIso8601String(),
    };

AppointmentDoctor _$AppointmentDoctorFromJson(Map<String, dynamic> json) =>
    AppointmentDoctor(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );

Map<String, dynamic> _$AppointmentDoctorToJson(AppointmentDoctor instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
    };

AppointmentData _$AppointmentDataFromJson(Map<String, dynamic> json) =>
    AppointmentData(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String,
      locationId: json['locationId'] as String?,
      eventId: json['eventId'] as String,
      specialtyId: json['specialtyId'] as String?,
      status: json['status'] as String,
      reason: json['reason'] as String?,
      priceAmount: (json['priceAmount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      createdAt: _dateTimeFromJson(json['createdAt']),
      patient: AppointmentPatient.fromJson(
          json['patient'] as Map<String, dynamic>),
      event: AppointmentEvent.fromJson(json['event'] as Map<String, dynamic>),
      doctor:
      AppointmentDoctor.fromJson(json['doctor'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppointmentDataToJson(AppointmentData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patientId': instance.patientId,
      'doctorId': instance.doctorId,
      'locationId': instance.locationId,
      'eventId': instance.eventId,
      'specialtyId': instance.specialtyId,
      'status': instance.status,
      'reason': instance.reason,
      'priceAmount': instance.priceAmount,
      'currency': instance.currency,
      'createdAt': instance.createdAt?.toIso8601String(),
      'patient': instance.patient,
      'event': instance.event,
      'doctor': instance.doctor,
    };