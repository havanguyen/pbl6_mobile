import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/model/services/remote/blog_service.dart';

class BlogVm extends ChangeNotifier {
  List<Blog> _blogs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _isOffline = false;
  int _currentPage = 1;
  final int _limit = 10;
  Map<String, dynamic> _meta = {};

  List<BlogCategory> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoryError;
  bool _isCategoryOffline = false;

  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedStatus;
  String _sortBy = 'createdAt';
  String _sortOrder = 'DESC';

  Blog? _blogDetail;
  bool _isLoadingDetail = false;

  List<Blog> get blogs => _blogs;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get isOffline => _isOffline;
  bool get hasNext => _meta['hasNext'] ?? false;

  List<BlogCategory> get categories => _categories;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoryError => _categoryError;
  bool get isCategoryOffline => _isCategoryOffline;


  Blog? get blogDetail => _blogDetail;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedStatus => _selectedStatus;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;

  BlogVm() {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isConnected = results.any((result) =>
      result == ConnectivityResult.wifi || result == ConnectivityResult.mobile);
      if (isConnected && (_isOffline || _isCategoryOffline)) {
        _isOffline = false;
        _isCategoryOffline = false;
        fetchBlogs(forceRefresh: true);
        fetchBlogCategories(forceRefresh: true);
      } else if (!isConnected) {
        _isOffline = true;
        _isCategoryOffline = true;
        _error = 'Bạn đang offline. Dữ liệu có thể đã cũ.';
        _categoryError = 'Bạn đang offline, không thể tải danh mục.';
        notifyListeners();
      }
    });
    fetchBlogCategories();
  }

  void updateSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      fetchBlogs(forceRefresh: true);
    }
  }

  void updateCategoryFilter(String? categoryId) {
    if (_selectedCategoryId != categoryId) {
      _selectedCategoryId = categoryId;
      fetchBlogs(forceRefresh: true);
    }
  }

  void updateStatusFilter(String? status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      fetchBlogs(forceRefresh: true);
    }
  }

  void updateSortFilter({String? sortBy, String? sortOrder}) {
    bool changed = false;
    if (sortBy != null && _sortBy != sortBy) {
      _sortBy = sortBy;
      changed = true;
    }
    if (sortOrder != null && _sortOrder != sortOrder) {
      _sortOrder = sortOrder;
      changed = true;
    }
    if (changed) {
      fetchBlogs(forceRefresh: true);
    }
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedStatus = null;
    _sortBy = 'createdAt';
    _sortOrder = 'DESC';
    fetchBlogs(forceRefresh: true);
  }

  Future<void> fetchBlogCategories({bool forceRefresh = false}) async {
    if (_isLoadingCategories && !forceRefresh) return;

    _isLoadingCategories = true;
    _categoryError = null;
    _isCategoryOffline = false;
    notifyListeners();

    try {
      final result = await BlogService.getBlogCategories();
      if (result.success) {
        _categories = result.data;
        _categoryError = null;
        _isCategoryOffline = false;
      } else {
        _categoryError = "Lỗi tải danh mục: ${result.message}";
        _isCategoryOffline = false;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown && e.error is SocketException)
      {
        _isCategoryOffline = true;
        _categoryError = 'Bạn đang offline, không thể tải danh mục.';
      } else {
        _isCategoryOffline = false;
        _categoryError = 'Lỗi máy chủ khi tải danh mục: ${e.response?.data['message'] ?? e.message}';
      }
    }
    catch (e) {
      _isCategoryOffline = false;
      _categoryError = 'Lỗi không mong muốn khi tải danh mục: $e';
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }


  Future<void> fetchBlogs({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _currentPage = 1;
      _meta = {};
      _blogs.clear();
      _isLoading = true;
    } else {
      if (_isLoading || _isLoadingMore || _isOffline || !hasNext) return;
      _isLoadingMore = true;
    }
    _error = null;
    _isOffline = false;
    notifyListeners();

    try {
      final result = await BlogService.getBlogs(
        search: _searchQuery,
        page: _currentPage,
        limit: _limit,
        categoryId: _selectedCategoryId,
        status: _selectedStatus,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      );

      if (result.success) {
        if (forceRefresh) {
          _blogs = result.data;
        } else {
          _blogs.addAll(result.data);
        }
        _meta = result.meta;
        if (hasNext) {
          _currentPage++;
        }
        _error = null;
        _isOffline = false;
      }
      else {
        _error = "Lỗi tải dữ liệu: ${result.message}";
        _isOffline = false;
      }
    }
    on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown && e.error is SocketException)
      {
        _isOffline = true;
        _error = 'Bạn đang offline. Dữ liệu có thể đã cũ.';
      } else {
        _isOffline = false;
        _error = 'Lỗi máy chủ hoặc yêu cầu: ${e.response?.data['message'] ?? e.message}';
      }
    }
    catch (e) {
      _isOffline = false;
      _error = 'Lỗi không mong muốn: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchBlogDetail(String id) async {
    _isLoadingDetail = true;
    _blogDetail = null;
    _error = null;
    notifyListeners();

    var connectivityResult = await Connectivity().checkConnectivity();
    bool localIsOffline = !connectivityResult.contains(ConnectivityResult.none);

    if (localIsOffline) {
      _error = 'Bạn đang offline, không thể tải chi tiết.';
      _isLoadingDetail = false;
      notifyListeners();
      return;
    }

    try {
      _blogDetail = await BlogService.getBlogDetail(id);
      if (_blogDetail == null) {
        _error = "Không tải được chi tiết blog hoặc blog không tồn tại.";
      }
    } catch (e) {
      _error = "Lỗi khi tải chi tiết blog: $e";
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }


  Future<void> loadMore() async {
    await fetchBlogs();
  }

  Future<bool> createBlog({
    required String title,
    required String content,
    required String categoryId,
    String? thumbnailUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    bool success = false;
    try {
      final newBlog = await BlogService.createBlog(
        title: title,
        content: content,
        categoryId: categoryId,
        thumbnailUrl: thumbnailUrl,
      );
      success = newBlog != null;
      if (success) {
        await fetchBlogs(forceRefresh: true);
      } else {
        _error = "Tạo blog thất bại.";
      }
    } catch (e) {
      _error = "Lỗi khi tạo blog: $e";
      success = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateBlog(String id, {
    String? title,
    String? content,
    String? categoryId,
    String? status,
    String? thumbnailUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    bool success = false;
    try {
      final updatedBlog = await BlogService.updateBlog(
        id,
        title: title,
        content: content,
        categoryId: categoryId,
        status: status,
        thumbnailUrl: thumbnailUrl,
      );
      success = updatedBlog != null;
      if (success) {
        int index = _blogs.indexWhere((blog) => blog.id == id);
        if (index != -1) {
          Blog? detail = await BlogService.getBlogDetail(id);
          if (detail != null) {
            _blogs[index] = detail;
          } else {
            await fetchBlogs(forceRefresh: true);
          }
        } else {
          await fetchBlogs(forceRefresh: true);
        }
      } else {
        _error = "Cập nhật blog thất bại.";
      }
    } catch (e) {
      _error = "Lỗi khi cập nhật blog: $e";
      success = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteBlog(String id, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    bool success = false;
    try {
      success = await BlogService.deleteBlog(id, password: password);
      if (success) {
        _blogs.removeWhere((blog) => blog.id == id);
      } else {
        _error = "Xóa blog thất bại. Vui lòng kiểm tra lại mật khẩu.";
      }
    } catch (e) {
      _error = "Lỗi khi xóa blog: $e";
      success = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}