import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String fullName,
    required String email,
    required String role,
    required String gender,
    DateTime? dateOfBirth,
    DateTime? deletedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String sessionId,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) => _$ProfileFromJson(json);

  @override
  // TODO: implement createdAt
  DateTime get createdAt => throw UnimplementedError();

  @override
  // TODO: implement dateOfBirth
  DateTime? get dateOfBirth => throw UnimplementedError();

  @override
  // TODO: implement deletedAt
  DateTime? get deletedAt => throw UnimplementedError();

  @override
  // TODO: implement email
  String get email => throw UnimplementedError();

  @override
  // TODO: implement fullName
  String get fullName => throw UnimplementedError();

  @override
  // TODO: implement gender
  String get gender => throw UnimplementedError();

  @override
  // TODO: implement id
  String get id => throw UnimplementedError();

  @override
  // TODO: implement role
  String get role => throw UnimplementedError();

  @override
  // TODO: implement sessionId
  String get sessionId => throw UnimplementedError();

  @override
  Map<String, dynamic> toJson() {
    // TODO: implement toJson
    throw UnimplementedError();
  }

  @override
  // TODO: implement updatedAt
  DateTime get updatedAt => throw UnimplementedError();
}