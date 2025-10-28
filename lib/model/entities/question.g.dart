part of 'question.dart';

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
  id: json['id'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  authorName: json['authorName'] as String,
  authorEmail: json['authorEmail'] as String,
  specialtyId: json['specialtyId'] as String?,
  publicIds: (json['publicIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList() ??
      [],
  status: json['status'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'body': instance.body,
  'authorName': instance.authorName,
  'authorEmail': instance.authorEmail,
  'specialtyId': instance.specialtyId,
  'publicIds': instance.publicIds,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};