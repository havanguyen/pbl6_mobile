class DoctorSlot {
  final String timeStart;
  final String timeEnd;
  final bool? isAvailable;

  DoctorSlot({
    required this.timeStart,
    required this.timeEnd,
    this.isAvailable,
  });

  factory DoctorSlot.fromJson(Map<String, dynamic> json) {
    return DoctorSlot(
      timeStart: json['timeStart'] as String,
      timeEnd: json['timeEnd'] as String,
      isAvailable: json['isAvailable'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeStart': timeStart,
      'timeEnd': timeEnd,
      'isAvailable': isAvailable,
    };
  }
}

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

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'patientId': patientId,
      'specialtyId': specialtyId,
    };

    if (eventId != null) data['eventId'] = eventId;
    if (serviceDate != null) data['serviceDate'] = serviceDate;
    if (timeStart != null) data['timeStart'] = timeStart;
    if (timeEnd != null) data['timeEnd'] = timeEnd;
    if (locationId != null) data['locationId'] = locationId;
    if (doctorId != null) data['doctorId'] = doctorId;
    if (reason != null) data['reason'] = reason;
    if (notes != null) data['notes'] = notes;
    if (priceAmount != null) data['priceAmount'] = priceAmount;
    if (currency != null) data['currency'] = currency;

    return data;
  }
}
