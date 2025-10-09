import 'package:pbl6mobile/model/entities/doctor.dart';

class GetDoctorsResponse {
  final List<Doctor> data;
  final bool success;
  final String message;
  final Map<String, dynamic> meta;

  GetDoctorsResponse({
    this.data = const [],
    required this.success,
    this.message = '',
    this.meta = const {},
  });
}