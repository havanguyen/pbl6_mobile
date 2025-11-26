// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DoctorSlot _$DoctorSlotFromJson(Map<String, dynamic> json) => DoctorSlot(
  timeStart: json['timeStart'] as String,
  timeEnd: json['timeEnd'] as String,
  isAvailable: json['isAvailable'] as bool?,
);

Map<String, dynamic> _$DoctorSlotToJson(DoctorSlot instance) =>
    <String, dynamic>{
      'timeStart': instance.timeStart,
      'timeEnd': instance.timeEnd,
      'isAvailable': instance.isAvailable,
    };

HoldAppointmentRequest _$HoldAppointmentRequestFromJson(
    Map<String, dynamic> json) =>
    HoldAppointmentRequest(
      doctorId: json['doctorId'] as String,
      locationId: json['locationId'] as String,
      serviceDate: json['serviceDate'] as String,
      timeStart: json['timeStart'] as String,
      timeEnd: json['timeEnd'] as String,
    );

Map<String, dynamic> _$HoldAppointmentRequestToJson(
    HoldAppointmentRequest instance) =>
    <String, dynamic>{
      'doctorId': instance.doctorId,
      'locationId': instance.locationId,
      'serviceDate': instance.serviceDate,
      'timeStart': instance.timeStart,
      'timeEnd': instance.timeEnd,
    };

CreateAppointmentRequest _$CreateAppointmentRequestFromJson(
    Map<String, dynamic> json) =>
    CreateAppointmentRequest(
      eventId: json['eventId'] as String?,
      serviceDate: json['serviceDate'] as String?,
      timeStart: json['timeStart'] as String?,
      timeEnd: json['timeEnd'] as String?,
      locationId: json['locationId'] as String?,
      doctorId: json['doctorId'] as String?,
      patientId: json['patientId'] as String,
      specialtyId: json['specialtyId'] as String,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      priceAmount: (json['priceAmount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );

Map<String, dynamic> _$CreateAppointmentRequestToJson(
    CreateAppointmentRequest instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'serviceDate': instance.serviceDate,
      'timeStart': instance.timeStart,
      'timeEnd': instance.timeEnd,
      'locationId': instance.locationId,
      'doctorId': instance.doctorId,
      'patientId': instance.patientId,
      'specialtyId': instance.specialtyId,
      'reason': instance.reason,
      'notes': instance.notes,
      'priceAmount': instance.priceAmount,
      'currency': instance.currency,
    };