part of 'answer.dart';

Answer _$AnswerFromJson(Map<String, dynamic> json) => Answer(
  id: json['id'] as String,
  body: json['body'] as String,
  authorId: json['authorId'] as String,
  authorName: json['authorFullName'] as String?,
  doctor: json['doctor'] == null
      ? null
      : Doctor.fromJson(json['doctor'] as Map<String, dynamic>),
  questionId: json['questionId'] as String,
  isAccepted: json['isAccepted'] as bool,
  upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$AnswerToJson(Answer instance) => <String, dynamic>{
  'id': instance.id,
  'body': instance.body,
  'authorId': instance.authorId,
  'authorName': instance.authorName,
  'doctor': instance.doctor,
  'questionId': instance.questionId,
  'isAccepted': instance.isAccepted,
  'upvotes': instance.upvotes,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
