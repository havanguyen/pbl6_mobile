import 'package:json_annotation/json_annotation.dart';

part 'question.g.dart';

@JsonSerializable()
class Question {
  final String id;
  final String title;
  final String body;
  final String authorName;
  final String authorEmail;
  final String? specialtyId;
  @JsonKey(defaultValue: [])
  final List<String> publicIds;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorEmail,
    this.specialtyId,
    required this.publicIds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}