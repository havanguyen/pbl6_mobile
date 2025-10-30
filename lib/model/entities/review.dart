import 'package:json_annotation/json_annotation.dart';

part 'review.g.dart';

@JsonSerializable()
class Review {
  final String id;
  final int rating;
  final String title;
  final String body;
  final String authorName;
  final String authorEmail;
  final String doctorId;
  final bool isPublic;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  final List<String> publicIds;

  Review({
    required this.id,
    required this.rating,
    required this.title,
    required this.body,
    required this.authorName,
    required this.authorEmail,
    required this.doctorId,
    required this.isPublic,
    required this.createdAt,
    required this.publicIds,
  });

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewToJson(this);

  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static String _dateTimeToJson(DateTime date) => date.toIso8601String();
}

class GetReviewsResponse {
  final bool success;
  final String? message;
  final List<Review> data;
  final Map<String, dynamic> meta;

  GetReviewsResponse({
    required this.success,
    this.message,
    this.data = const [],
    this.meta = const {},
  });
}