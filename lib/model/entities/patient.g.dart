part of 'patient.dart';

Patient _$PatientFromJson(Map<String, dynamic> json) => Patient(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String,
  phone: json['phone'] as String?,
  isMale: Patient._boolFromJson(json['isMale']),
  dateOfBirth: Patient._dateTimeFromJson(json['dateOfBirth']),
  addressLine: json['addressLine'] as String?,
  district: json['district'] as String?,
  province: json['province'] as String?,
  createdAt: Patient._dateTimeFromJson(json['createdAt']),
  updatedAt: Patient._dateTimeFromJson(json['updatedAt']),
  deletedAt: Patient._dateTimeFromJson(json['deletedAt']),
);

Map<String, dynamic> _$PatientToJson(Patient instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'email': instance.email,
    'fullName': instance.fullName,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('phone', instance.phone);
  val['isMale'] = instance.isMale;
  val['dateOfBirth'] = Patient._dateTimeToJson(instance.dateOfBirth);
  val['addressLine'] = instance.addressLine;
  val['district'] = instance.district;
  val['province'] = instance.province;
  val['createdAt'] = Patient._dateTimeToJson(instance.createdAt);
  val['updatedAt'] = Patient._dateTimeToJson(instance.updatedAt);
  val['deletedAt'] = Patient._dateTimeToJson(instance.deletedAt);
  return val;
}