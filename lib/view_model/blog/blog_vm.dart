import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/model/services/remote/blog_service.dart';
import 'package:pbl6mobile/model/services/remote/utilities_service.dart';

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

  bool _isUpdatingEntity = false;
  bool get isUpdatingEntity => _isUpdatingEntity;

  File? _selectedThumbnailFile;
  File? get selectedThumbnailFile => _selectedThumbnailFile;

  String? _uploadedThumbnailUrl;
  String? get uploadedThumbnailUrl => _uploadedThumbnailUrl;
  bool _isUploadingThumbnail = false;
  bool get isUploadingThumbnail => _isUploadingThumbnail;
  String? _thumbnailUploadError;
  String? get thumbnailUploadError => _thumbnailUploadError;

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

  Future<bool> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    bool isConnected = connectivityResult.any((result) =>
    result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet);
    _isOffline = !isConnected;
    return isConnected;
  }

  BlogVm() {
    _checkConnectivity().then((_) => notifyListeners());

    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      bool isConnected = results.any((result) =>
      result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet);
      bool wasOffline = _isOffline || _isCategoryOffline;
      _isOffline = !isConnected;
      _isCategoryOffline = !isConnected;

      if (!isConnected) {
        _error = 'Bạn đang offline. Dữ liệu có thể đã cũ.';
        _categoryError = 'Bạn đang offline, không thể tải danh mục.';
      } else if (isConnected && wasOffline) {
        _error = null;
        _categoryError = null;
        fetchBlogs(forceRefresh: true);
        fetchBlogCategories(forceRefresh: true);
      }
      notifyListeners();
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

  void _handleError(dynamic e, {bool isCategoryError = false}) {
    String message;
    if (e is DioException) {
      message = 'Lỗi máy chủ: ${e.response?.data['message'] ?? e.message}';
    } else {
      message = 'Lỗi không mong muốn: $e';
    }

    if (isCategoryError) {
      _categoryError = message;
    } else {
      _error = message;
    }
  }

  Future<void> fetchBlogCategories({bool forceRefresh = false}) async {
    if (_isLoadingCategories && !forceRefresh) return;
    if (!await _checkConnectivity()) {
      _categoryError = 'Bạn đang offline, không thể tải danh mục.';
      _isCategoryOffline = true;
      notifyListeners();
      return;
    }

    _isLoadingCategories = true;
    _categoryError = null;
    _isCategoryOffline = false;
    if (forceRefresh) {
      notifyListeners();
    }

    try {
      final result = await BlogService.getBlogCategories();
      if (result.success) {
        _categories = result.data;
      } else {
        _categoryError = "Lỗi tải danh mục: ${result.message}";
      }
    } catch (e) {
      _handleError(e, isCategoryError: true);
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> fetchBlogs({bool forceRefresh = false}) async {
    if (forceRefresh) {
      if (!await _checkConnectivity()) {
        _error = 'Bạn đang offline, không thể tải dữ liệu.';
        _isOffline = true;
        _isLoading = false;
        notifyListeners();
        return;
      }
      _currentPage = 1;
      _meta = {};
      _blogs.clear();
      _isLoading = true;
    } else {
      if (_isLoading || _isLoadingMore || !hasNext) return;
      if (!await _checkConnectivity()) {
        _error = 'Bạn đang offline, không thể tải thêm.';
        _isOffline = true;
        notifyListeners();
        return;
      }
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
      } else {
        _error = "Lỗi tải dữ liệu: ${result.message}";
      }
    } catch (e) {
      _handleError(e);
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> fetchBlogDetail(String id) async {
    if (!await _checkConnectivity()) {
      _error = 'Bạn đang offline, không thể tải chi tiết.';
      _isLoadingDetail = false;
      notifyListeners();
      return;
    }

    _isLoadingDetail = true;
    _blogDetail = null;
    _error = null;
    notifyListeners();

    try {
      _blogDetail = await BlogService.getBlogDetail(id);
      if (_blogDetail == null) {
        _error = "Không tải được chi tiết blog hoặc blog không tồn tại.";
      }
    } catch (e) {
      _handleError(e);
      _error = "Lỗi khi tải chi tiết blog: $_error";
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    await fetchBlogs();
  }

  Future<void> pickThumbnailImage() async {
    _selectedThumbnailFile = null;
    _thumbnailUploadError = null;
    _uploadedThumbnailUrl = null;
    notifyListeners();
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024);
      if (pickedFile != null) {
        _selectedThumbnailFile = File(pickedFile.path);
        notifyListeners();
        await uploadThumbnailImage();
      }
    } catch (e) {
      _thumbnailUploadError = "Lỗi khi chọn ảnh: $e";
      notifyListeners();
    }
  }

  Future<String?> uploadThumbnailImage() async {
    if (_selectedThumbnailFile == null) return null;
    if (!await _checkConnectivity()) {
      _thumbnailUploadError = 'Bạn đang offline, không thể upload ảnh.';
      notifyListeners();
      return null;
    }

    _isUploadingThumbnail = true;
    _thumbnailUploadError = null;
    notifyListeners();

    String? imageUrl;
    Map<String, dynamic>? signatureData;

    try {
      signatureData = await UtilitiesService.getUploadSignature();
      if (signatureData == null) {
        _thumbnailUploadError = "Không thể lấy chữ ký upload.";
        _isUploadingThumbnail = false;
        notifyListeners();
        return null;
      }

      imageUrl = await UtilitiesService.uploadImageToCloudinary(
          _selectedThumbnailFile!.path, signatureData);

      if (imageUrl != null) {
        _uploadedThumbnailUrl = imageUrl;
      } else {
        _thumbnailUploadError = "Upload ảnh lên Cloudinary thất bại.";
      }
    } catch (e) {
      _handleError(e);
      _thumbnailUploadError = "Lỗi upload ảnh: $_error";
      _error = null;
    } finally {
      _isUploadingThumbnail = false;
      notifyListeners();
    }
    return imageUrl;
  }

  void resetThumbnailState({bool notify = true}) {
    _selectedThumbnailFile = null;
    _uploadedThumbnailUrl = null;
    _thumbnailUploadError = null;
    _isUploadingThumbnail = false;
    if (notify) {
      notifyListeners();
    }
  }

  Future<bool> createBlog({
    required String title,
    required String content,
    required String categoryId,
    String? thumbnailUrl,
  }) async {
    if (!await _checkConnectivity()) {
      _error = 'Bạn đang offline, không thể tạo blog.';
      notifyListeners();
      return false;
    }

    _isUpdatingEntity = true;
    _error = null;
    notifyListeners();
    bool success = false;

    String? finalThumbnailUrl = thumbnailUrl;
    if (_selectedThumbnailFile != null) {
      if (_isUploadingThumbnail) {
        _error = "Đang upload ảnh thumbnail, vui lòng chờ...";
        _isUpdatingEntity = false;
        notifyListeners();
        return false;
      }
      if (_uploadedThumbnailUrl != null) {
        finalThumbnailUrl = _uploadedThumbnailUrl;
      } else {
        _error = _thumbnailUploadError ?? "Lỗi upload ảnh thumbnail.";
        _isUpdatingEntity = false;
        notifyListeners();
        return false;
      }
    }

    try {
      final newBlog = await BlogService.createBlog(
        title: title,
        content: content,
        categoryId: categoryId,
        thumbnailUrl: finalThumbnailUrl,
      );
      success = newBlog != null;
      if (success) {
        resetThumbnailState(notify: false);
        await fetchBlogs(forceRefresh: true);
      } else {
        _error = "Tạo blog thất bại.";
      }
    } catch (e) {
      _handleError(e);
      _error = "Lỗi khi tạo blog: $_error";
      success = false;
    } finally {
      _isUpdatingEntity = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateBlog(
      String id, {
        String? title,
        String? content,
        String? categoryId,
        String? status,
        String? thumbnailUrl,
      }) async {
    if (!await _checkConnectivity()) {
      _error = 'Bạn đang offline, không thể cập nhật blog.';
      notifyListeners();
      return false;
    }

    _isUpdatingEntity = true;
    _error = null;
    notifyListeners();
    bool success = false;

    String? finalThumbnailUrl = thumbnailUrl;
    if (_selectedThumbnailFile != null) {
      if (_isUploadingThumbnail) {
        _error = "Đang upload ảnh thumbnail, vui lòng chờ...";
        _isUpdatingEntity = false;
        notifyListeners();
        return false;
      }
      if (_uploadedThumbnailUrl != null) {
        finalThumbnailUrl = _uploadedThumbnailUrl;
      } else {
        _error = _thumbnailUploadError ?? "Lỗi upload ảnh thumbnail.";
        _isUpdatingEntity = false;
        notifyListeners();
        return false;
      }
    }

    try {
      final updatedBlog = await BlogService.updateBlog(id,
          title: title,
          content: content,
          categoryId: categoryId,
          status: status,
          thumbnailUrl: finalThumbnailUrl);

      success = updatedBlog != null;
      if (success) {
        resetThumbnailState(notify: false);
        _blogDetail = updatedBlog;
        int index = _blogs.indexWhere((blog) => blog.id == id);
        if (index != -1) {
          _blogs[index] = updatedBlog;
        } else {
          await fetchBlogs(forceRefresh: true);
        }
      } else {
        _error = "Cập nhật blog thất bại.";
      }
    } catch (e) {
      _handleError(e);
      _error = "Lỗi khi cập nhật blog: $_error";
      success = false;
    } finally {
      _isUpdatingEntity = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteBlog(String id, String password) async {
    if (!await _checkConnectivity()) {
      _error = 'Bạn đang offline, không thể xóa blog.';
      notifyListeners();
      return false;
    }

    _isUpdatingEntity = true;
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
      _handleError(e);
      _error = "Lỗi khi xóa blog: $_error";
      success = false;
    } finally {
      _isUpdatingEntity = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> createBlogCategory({
    required String name,
    String? description,
  }) async {
    if (!await _checkConnectivity()) {
      _categoryError = 'Bạn đang offline, không thể tạo danh mục.';
      notifyListeners();
      return false;
    }
    _isUpdatingEntity = true;
    _categoryError = null;
    notifyListeners();
    bool success = false;
    try {
      final newCategory = await BlogService.createBlogCategory(
        name: name,
        description: description,
      );
      success = newCategory != null;
      if (success) {
        await fetchBlogCategories(forceRefresh: true);
      } else {
        _categoryError = "Tạo danh mục thất bại.";
      }
    } catch (e) {
      _handleError(e, isCategoryError: true);
      _categoryError = "Lỗi khi tạo danh mục: $_categoryError";
      success = false;
    } finally {
      _isUpdatingEntity = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateBlogCategory(
      String id, {
        String? name,
        String? description,
      }) async {
    if (!await _checkConnectivity()) {
      _categoryError = 'Bạn đang offline, không thể cập nhật danh mục.';
      notifyListeners();
      return false;
    }
    _isUpdatingEntity = true;
    _categoryError = null;
    notifyListeners();
    bool success = false;
    try {
      final updatedCategory = await BlogService.updateBlogCategory(
        id,
        name: name,
        description: description,
      );
      success = updatedCategory != null;
      if (success) {
        await fetchBlogCategories(forceRefresh: true);
      } else {
        _categoryError = "Cập nhật danh mục thất bại.";
      }
    } catch (e) {
      _handleError(e, isCategoryError: true);
      _categoryError = "Lỗi khi cập nhật danh mục: $_categoryError";
      success = false;
    } finally {
      _isUpdatingEntity = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteBlogCategory(String id,
      {required String password, bool forceBulkDelete = false}) async {
    if (!await _checkConnectivity()) {
      _categoryError = 'Bạn đang offline, không thể xóa danh mục.';
      notifyListeners();
      return false;
    }
    _isUpdatingEntity = true;
    _categoryError = null;
    notifyListeners();
    bool success = false;
    try {
      success = await BlogService.deleteBlogCategory(id,
          password: password, forceBulkDelete: forceBulkDelete);
      if (success) {
        _categories.removeWhere((cat) => cat.id == id);
        await fetchBlogs(forceRefresh: true);
      } else {
        _categoryError =
        "Xóa thất bại. Sai mật khẩu hoặc danh mục đang được sử dụng.";
      }
    } catch (e) {
      _handleError(e, isCategoryError: true);
      _categoryError = "Lỗi khi xóa danh mục: $_categoryError";
      success = false;
    } finally {
      _isUpdatingEntity = false;
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

  void clearCategoryError() {
    if (_categoryError != null) {
      _categoryError = null;
      notifyListeners();
    }
  }
}