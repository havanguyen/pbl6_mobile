class AppointmentPatient {
  final String fullName;
  final DateTime? dateOfBirth;

  AppointmentPatient({required this.fullName, this.dateOfBirth});

  factory AppointmentPatient.fromJson(Map<String, dynamic> json) {
    return AppointmentPatient(
      fullName: json['fullName'] as String? ?? '',
      dateOfBirth: _dateTimeFromJson(json['dateOfBirth']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentPatient &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          dateOfBirth == other.dateOfBirth;

  @override
  int get hashCode => Object.hash(fullName, dateOfBirth);
}

class AppointmentEvent {
  final String id;
  final DateTime? serviceDate;
  final DateTime? timeStart;
  final DateTime? timeEnd;

  AppointmentEvent({
    required this.id,
    this.serviceDate,
    this.timeStart,
    this.timeEnd,
  });

  factory AppointmentEvent.fromJson(Map<String, dynamic> json) {
    return AppointmentEvent(
      id: json['id'] as String? ?? '',
      serviceDate: _dateTimeFromJson(json['serviceDate']),
      timeStart: _dateTimeFromJson(json['timeStart']),
      timeEnd: _dateTimeFromJson(json['timeEnd']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceDate': serviceDate?.toIso8601String(),
      'timeStart': timeStart?.toIso8601String(),
      'timeEnd': timeEnd?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AppointmentDoctor {
  final String id;
  final String? name;
  final String? avatarUrl;

  AppointmentDoctor({required this.id, this.name, this.avatarUrl});

  factory AppointmentDoctor.fromJson(Map<String, dynamic> json) {
    return AppointmentDoctor(
      id: json['id'] as String? ?? '',
      name: (json['name'] ?? json['fullName']) as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'avatarUrl': avatarUrl};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentDoctor &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AppointmentData {
  final String id;
  final String patientId;
  final String doctorId;
  final String? locationId;
  final String eventId;
  final String? specialtyId;
  final String status;
  final String? reason;
  final String? notes;
  final double? priceAmount;
  final String? currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

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
    this.notes,
    this.priceAmount,
    this.currency,
    this.createdAt,
    this.updatedAt,
    this.cancelledAt,
    this.completedAt,
    required this.patient,
    required this.event,
    required this.doctor,
  });

  factory AppointmentData.fromJson(Map<String, dynamic> json) {
    return AppointmentData(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      locationId: json['locationId'] as String?,
      eventId: json['eventId'] as String? ?? '',
      specialtyId: json['specialtyId'] as String?,
      status: json['status'] as String? ?? 'BOOKED',
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      priceAmount: _parseDouble(json['priceAmount']),
      currency: json['currency'] as String?,
      createdAt: _dateTimeFromJson(json['createdAt']),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
      cancelledAt: _dateTimeFromJson(json['cancelledAt']),
      completedAt: _dateTimeFromJson(json['completedAt']),
      patient: json['patient'] != null
          ? AppointmentPatient.fromJson(json['patient'] as Map<String, dynamic>)
          : AppointmentPatient(fullName: 'Unknown Patient'),
      event: json['event'] != null
          ? AppointmentEvent.fromJson(json['event'] as Map<String, dynamic>)
          : AppointmentEvent(id: '', serviceDate: DateTime.now()),
      doctor: json['doctor'] != null
          ? AppointmentDoctor.fromJson(json['doctor'] as Map<String, dynamic>)
          : AppointmentDoctor(id: '', name: 'Unknown Doctor'),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'locationId': locationId,
      'eventId': eventId,
      'specialtyId': specialtyId,
      'status': status,
      'reason': reason,
      'notes': notes,
      'priceAmount': priceAmount,
      'currency': currency,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'patient': patient.toJson(),
      'event': event.toJson(),
      'doctor': doctor.toJson(),
    };
  }

  DateTime get appointmentStartTime {
    if (event.serviceDate == null || event.timeStart == null) {
      return DateTime(1970, 1, 1);
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
      return DateTime(1970, 1, 1).add(const Duration(minutes: 30));
    }
    return DateTime(
      event.serviceDate!.year,
      event.serviceDate!.month,
      event.serviceDate!.day,
      event.timeEnd!.hour,
      event.timeEnd!.minute,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentData &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null || value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
