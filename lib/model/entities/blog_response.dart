import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';

class GetBlogsResponse {
  final List<Blog> data;
  final bool success;
  final String message;
  final Map<String, dynamic> meta;

  GetBlogsResponse({
    this.data = const [],
    required this.success,
    this.message = '',
    this.meta = const {},
  });
}

class GetBlogCategoriesResponse {
  final List<BlogCategory> data;
  final bool success;
  final String message;

  GetBlogCategoriesResponse({
    this.data = const [],
    required this.success,
    this.message = '',
  });
}