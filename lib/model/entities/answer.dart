import 'package:json_annotation/json_annotation.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';

part 'answer.g.dart';

@JsonSerializable()
class Answer {
  final String id;
  final String body;
  final String authorId;
  final String? authorName;
  final Doctor? doctor;
  final String questionId;
  final bool isAccepted;
  final int upvotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Answer({
    required this.id,
    required this.body,
    required this.authorId,
    this.authorName,
    this.doctor,
    required this.questionId,
    required this.isAccepted,
    this.upvotes = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);
  Map<String, dynamic> toJson() => _$AnswerToJson(this);
}
