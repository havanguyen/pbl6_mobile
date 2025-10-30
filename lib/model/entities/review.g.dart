part of 'review.dart';

Review _$ReviewFromJson(Map<String, dynamic> json) => Review(
  id: json['id'] as String,
  rating: (json['rating'] as num).toInt(),
  title: json['title'] as String,
  body: json['body'] as String,
  authorName: json['authorName'] as String,
  authorEmail: json['authorEmail'] as String,
  doctorId: json['doctorId'] as String,
  isPublic: json['isPublic'] as bool,
  createdAt: Review._dateTimeFromJson(json['createdAt']),
  publicIds:
  (json['publicIds'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$ReviewToJson(Review instance) => <String, dynamic>{
  'id': instance.id,
  'rating': instance.rating,
  'title': instance.title,
  'body': instance.body,
  'authorName': instance.authorName,
  'authorEmail': instance.authorEmail,
  'doctorId': instance.doctorId,
  'isPublic': instance.isPublic,
  'createdAt': Review._dateTimeToJson(instance.createdAt),
  'publicIds': instance.publicIds,
};