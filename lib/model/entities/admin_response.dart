import 'package:pbl6mobile/model/entities/staff.dart';

class GetAdminsResponse {
  final List<Staff> data;
  final bool success;
  final String message;
  final Map<String, dynamic> meta;

  GetAdminsResponse({
    this.data = const [],
    required this.success,
    this.message = '',
    this.meta = const {},
  });
}