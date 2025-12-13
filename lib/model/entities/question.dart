import 'package:json_annotation/json_annotation.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';

part 'question.g.dart';

@JsonSerializable()
class Question {
  final String id;
  final String title;
  final String? slug;
  final String body;
  final String authorName;
  final String authorEmail;
  final String? specialtyId;
  final Specialty? specialty;
  @JsonKey(defaultValue: [])
  final List<String> publicIds;
  final int answerCount;
  final int acceptedAnswerCount;
  final int viewCount;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Question({
    required this.id,
    required this.title,
    this.slug,
    required this.body,
    required this.authorName,
    required this.authorEmail,
    this.specialtyId,
    this.specialty,
    required this.publicIds,
    this.answerCount = 0,
    this.acceptedAnswerCount = 0,
    this.viewCount = 0,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}
