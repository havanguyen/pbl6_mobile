import 'package:json_annotation/json_annotation.dart';

part 'answer.g.dart';

@JsonSerializable()
class Answer {
  final String id;
  final String body;
  final String authorId;
  final String questionId;
  final bool isAccepted;
  final DateTime createdAt;
  final DateTime updatedAt;

  Answer({
    required this.id,
    required this.body,
    required this.authorId,
    required this.questionId,
    required this.isAccepted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);
  Map<String, dynamic> toJson() => _$AnswerToJson(this);
}