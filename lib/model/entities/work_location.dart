import 'package:json_annotation/json_annotation.dart';

part 'work_location.g.dart';

@JsonSerializable()
class WorkLocation {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String timezone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.timezone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkLocation.fromJson(Map<String, dynamic> json) => _$WorkLocationFromJson(json);
  Map<String, dynamic> toJson() => _$WorkLocationToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WorkLocation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}