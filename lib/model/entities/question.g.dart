part of 'question.dart';

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
  id: json['id'] as String,
  title: json['title'] as String,
  slug: json['slug'] as String?,
  body: json['body'] as String,
  authorName: json['authorName'] as String,
  authorEmail: json['authorEmail'] as String,
  specialtyId: json['specialtyId'] as String?,
  specialty: json['specialty'] == null
      ? null
      : Specialty.fromJson(json['specialty'] as Map<String, dynamic>),
  publicIds:
      (json['publicIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  answerCount: (json['answersCount'] as num?)?.toInt() ?? 0,
  acceptedAnswerCount: (json['acceptedAnswersCount'] as num?)?.toInt() ?? 0,
  viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'slug': instance.slug,
  'body': instance.body,
  'authorName': instance.authorName,
  'authorEmail': instance.authorEmail,
  'specialtyId': instance.specialtyId,
  'specialty': instance.specialty,
  'publicIds': instance.publicIds,
  'answersCount': instance.answerCount,
  'acceptedAnswersCount': instance.acceptedAnswerCount,
  'viewCount': instance.viewCount,
  'status': instance.status,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
