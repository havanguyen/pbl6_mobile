import 'package:dio/dio.dart';
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/model/entities/blog_response.dart';
import 'package:pbl6mobile/model/services/remote/auth_service.dart';

class BlogService {
  const BlogService._();

  static final Dio _secureDio = AuthService.getSecureDioInstance();

  static Future<GetBlogsResponse> getBlogs({
    int page = 1,
    int limit = 10,
    String? categoryId,
    String? status,
    String? search,
    String sortBy = 'createdAt',
    String sortOrder = 'DESC',
  }) async {
    try {
      final params = {
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _secureDio.get('/blogs', queryParameters: params);

      if (response.statusCode == 200) {
        final blogList = (response.data['data'] as List)
            .map((json) => Blog.fromJson(json as Map<String, dynamic>))
            .toList();
        return GetBlogsResponse(
          success: true,
          data: blogList,
          meta: response.data['meta'] ?? {},
        );
      }
      return GetBlogsResponse(success: false, message: response.data['message'] ?? 'API call failed');
    } on DioException catch (e) {
      return GetBlogsResponse(success: false, message: 'Lỗi kết nối: ${e.message} ${e.response?.data['message']}');
    } catch (e) {
      return GetBlogsResponse(success: false, message: 'Lỗi không mong muốn: $e');
    }
  }

  static Future<Blog?> getBlogDetail(String id) async {
    try {
      final response = await _secureDio.get('/blogs/$id');
      if (response.statusCode == 200 && response.data['data'] != null) {
        return Blog.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print("Get Blog Detail Error: $e");
      if (e is DioException) print("DioException: ${e.response?.data}");
      return null;
    }
  }

  static Future<GetBlogCategoriesResponse> getBlogCategories() async {
    try {
      final response = await _secureDio.get('/blogs/categories');

      if (response.statusCode == 200) {
        final categoryList = (response.data['data'] as List)
            .map((json) => BlogCategory.fromJson(json as Map<String, dynamic>))
            .toList();
        return GetBlogCategoriesResponse(
          success: true,
          data: categoryList,
        );
      }
      return GetBlogCategoriesResponse(success: false, message: response.data['message'] ?? 'API call failed');
    } on DioException catch (e) {
      return GetBlogCategoriesResponse(success: false, message: 'Lỗi kết nối: ${e.message} ${e.response?.data['message']}');
    } catch (e) {
      return GetBlogCategoriesResponse(success: false, message: 'Lỗi không mong muốn: $e');
    }
  }

  static Future<Blog?> createBlog({
    required String title,
    required String content,
    required String categoryId,
    String? thumbnailUrl,
  }) async {
    try {
      final requestBody = {
        'title': title,
        'content': content,
        'categoryId': categoryId,
        if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) 'thumbnailUrl': thumbnailUrl,
      };
      final response = await _secureDio.post('/blogs', data: requestBody);
      if (response.statusCode == 201 && response.data['data'] != null) {
        return Blog.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print("Create Blog Error: $e");
      if (e is DioException) print("DioException: ${e.response?.data}");
      return null;
    }
  }

  static Future<Blog?> updateBlog(String id, {
    String? title,
    String? content,
    String? categoryId,
    String? status,
    String? thumbnailUrl,
  }) async {
    try {
      final requestBody = {
        if (title != null && title.isNotEmpty) 'title': title,
        if (content != null && content.isNotEmpty) 'content': content,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (status != null && status.isNotEmpty) 'status': status,
      };
      if (requestBody.isEmpty) return null;

      final response = await _secureDio.patch('/blogs/$id', data: requestBody);
      if (response.statusCode == 200 && response.data['data'] != null) {
        return Blog.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print("Update Blog Error: $e");
      if (e is DioException) print("DioException: ${e.response?.data}");
      return null;
    }
  }

  static Future<bool> deleteBlog(String id, {required String password}) async {
    try {
      if (!await AuthService.verifyPassword(password: password)) {
        print('Password verification failed for deleting blog');
        return false;
      }
      final response = await _secureDio.delete('/blogs/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Delete Blog Error: $e");
      if (e is DioException) print("DioException: ${e.response?.data}");
      return false;
    }
  }
}