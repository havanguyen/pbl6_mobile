part of 'answer.dart';

Answer _$AnswerFromJson(Map<String, dynamic> json) => Answer(
  id: json['id'] as String,
  body: json['body'] as String,
  authorId: json['authorId'] as String,
  questionId: json['questionId'] as String,
  isAccepted: json['isAccepted'] as bool,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$AnswerToJson(Answer instance) => <String, dynamic>{
  'id': instance.id,
  'body': instance.body,
  'authorId': instance.authorId,
  'questionId': instance.questionId,
  'isAccepted': instance.isAccepted,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};