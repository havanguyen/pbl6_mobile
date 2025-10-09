import 'package:pbl6mobile/model/entities/specialty.dart';

class GetSpecialtiesResponse {
  final List<Specialty> data;
  final bool success;
  final String message;
  final Map<String, dynamic> meta;

  GetSpecialtiesResponse({
    this.data = const [],
    required this.success,
    this.message = '',
    this.meta = const {},
  });
}