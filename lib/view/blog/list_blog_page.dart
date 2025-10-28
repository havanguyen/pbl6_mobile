import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';

import '../../shared/widgets/widget/blog_delete_confirm.dart';

class ListBlogPage extends StatefulWidget {
  const ListBlogPage({super.key});

  @override
  State<ListBlogPage> createState() => _ListBlogPageState();
}

class _ListBlogPageState extends State<ListBlogPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BlogVm>().fetchBlogs(forceRefresh: true);
        context.read<BlogVm>().fetchBlogCategories();
      }
    });

    _searchController.addListener(_debounceSearch);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_debounceSearch);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BlogVm>().loadMore();
    }
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        context.read<BlogVm>().updateSearchQuery(_searchController.text);
      }
    });
  }

  void _showDeleteDialog(Blog blog) {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    final blogVm = Provider.of<BlogVm>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangeNotifierProvider.value(
        value: blogVm,
        child: BlogDeleteConfirmationDialog(
          blog: blog.toJson(),
          onDeleteSuccess: () {},
          snackbarService: snackbarService,
        ),
      ),
    );
  }

  void _showFilterSheet() {
    final blogVm = context.read<BlogVm>();
    if (blogVm.categories.isEmpty &&
        !blogVm.isLoadingCategories &&
        !blogVm.isCategoryOffline) {
      blogVm.fetchBlogCategories(forceRefresh: true);
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: context.theme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: _buildFilterSection(),
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isOffline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: context.theme.textColor),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tiêu đề',
              hintStyle: TextStyle(
                  color: context.theme.mutedForeground.withOpacity(0.7)),
              prefixIcon:
              Icon(Icons.search, color: context.theme.primary, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.theme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.theme.primary, width: 1.5),
              ),
              filled: true,
              fillColor: context.theme.input,
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear,
                    color: context.theme.mutedForeground, size: 20),
                onPressed: () {
                  _searchController.clear();
                },
              )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 20),
                  label:
                  const Text('Thêm bài viết', style: TextStyle(fontSize: 15)),
                  onPressed: isOffline
                      ? null
                      : () async {
                    final result =
                    await Navigator.pushNamed(context, Routes.createBlog);
                    if (result == true) {}
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primary,
                    foregroundColor: context.theme.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return context.theme.muted;
                        }
                        return context.theme.primary;
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return context.theme.mutedForeground;
                        }
                        return context.theme.primaryForeground;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: context.theme.input,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _showFilterSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.theme.border)),
                    child: Icon(Icons.filter_list_rounded,
                        color: context.theme.primary, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Consumer<BlogVm>(builder: (context, blogVm, child) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bộ lọc & Sắp xếp',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.theme.textColor)),
                TextButton.icon(
                  icon: Icon(Icons.refresh,
                      size: 18, color: context.theme.mutedForeground),
                  label: Text('Đặt lại',
                      style: TextStyle(color: context.theme.mutedForeground)),
                  onPressed: () {
                    blogVm.resetFilters();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                )
              ],
            ),
            const Divider(height: 24),
            Text('Danh mục',
                style: TextStyle(
                    color: context.theme.textColor,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            blogVm.isLoadingCategories
                ? const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))))
                : blogVm.isCategoryOffline || blogVm.categoryError != null
                ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: context.theme.destructive.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: context.theme.destructive
                          .withOpacity(0.3))),
              child: Row(
                children: [
                  Icon(
                      blogVm.isCategoryOffline
                          ? Icons.wifi_off_rounded
                          : Icons.error_outline_rounded,
                      color: context.theme.destructive,
                      size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          blogVm.categoryError ?? 'Lỗi không xác định',
                          style: TextStyle(
                              color: context.theme.destructive,
                              fontSize: 13))),
                  TextButton(
                    onPressed: () =>
                        blogVm.fetchBlogCategories(forceRefresh: true),
                    child: Text("Thử lại",
                        style:
                        TextStyle(color: context.theme.primary)),
                  )
                ],
              ),
            )
                : DropdownButtonFormField<String>(
              value: blogVm.categories
                  .any((c) => c.id == blogVm.selectedCategoryId)
                  ? blogVm.selectedCategoryId
                  : null,
              hint: Text('Tất cả danh mục',
                  style:
                  TextStyle(color: context.theme.mutedForeground)),
              isExpanded: true,
              style:
              TextStyle(color: context.theme.textColor, fontSize: 15),
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: context.theme.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: context.theme.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      BorderSide(color: context.theme.primary)),
                  filled: true,
                  fillColor: context.theme.input,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    size: 18,
                    color: context.theme.mutedForeground,
                  )),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: context.theme.mutedForeground),
              dropdownColor: context.theme.popover,
              items: [
                DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tất cả danh mục',
                        style: TextStyle(
                            color: context.theme.mutedForeground))),
                ...blogVm.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.name,
                        style: TextStyle(
                            color: context.theme.popoverForeground)),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                blogVm.updateCategoryFilter(value);
              },
              validator: (value) {
                if (blogVm.categories.isEmpty &&
                    !blogVm.isLoadingCategories &&
                    blogVm.categoryError != null) {
                  return 'Không thể tải danh mục';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('Trạng thái',
                style: TextStyle(
                    color: context.theme.textColor,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: blogVm.selectedStatus,
              hint: Text('Tất cả trạng thái',
                  style: TextStyle(color: context.theme.mutedForeground)),
              isExpanded: true,
              style: TextStyle(color: context.theme.textColor, fontSize: 15),
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.theme.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.theme.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: context.theme.primary)),
                  filled: true,
                  fillColor: context.theme.input,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  prefixIcon: Icon(
                    Icons.toggle_on_outlined,
                    size: 18,
                    color: context.theme.mutedForeground,
                  )),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: context.theme.mutedForeground),
              dropdownColor: context.theme.popover,
              items: [
                DropdownMenuItem<String>(
                    value: null,
                    child: Text('Tất cả trạng thái',
                        style:
                        TextStyle(color: context.theme.mutedForeground))),
                DropdownMenuItem<String>(
                    value: 'DRAFT',
                    child: Text('Bản nháp',
                        style: TextStyle(
                            color: context.theme.popoverForeground))),
                DropdownMenuItem<String>(
                    value: 'PUBLISHED',
                    child: Text('Đã xuất bản',
                        style: TextStyle(
                            color: context.theme.popoverForeground))),
                DropdownMenuItem<String>(
                    value: 'ARCHIVED',
                    child: Text('Đã lưu trữ',
                        style: TextStyle(
                            color: context.theme.popoverForeground))),
              ],
              onChanged: (value) {
                blogVm.updateStatusFilter(value);
              },
            ),
            const SizedBox(height: 20),
            Text('Sắp xếp',
                style: TextStyle(
                    color: context.theme.textColor,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                      value: blogVm.sortBy,
                      style:
                      TextStyle(color: context.theme.textColor, fontSize: 15),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: context.theme.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: context.theme.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: context.theme.primary)),
                        filled: true,
                        fillColor: context.theme.input,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: context.theme.mutedForeground),
                      dropdownColor: context.theme.popover,
                      items: [
                        DropdownMenuItem(
                            value: 'createdAt',
                            child: Text('Ngày tạo',
                                style: TextStyle(
                                    color: context.theme.popoverForeground))),
                        DropdownMenuItem(
                            value: 'updatedAt',
                            child: Text('Ngày cập nhật',
                                style: TextStyle(
                                    color: context.theme.popoverForeground))),
                        DropdownMenuItem(
                            value: 'publishedAt',
                            child: Text('Ngày xuất bản',
                                style: TextStyle(
                                    color: context.theme.popoverForeground))),
                        DropdownMenuItem(
                            value: 'title',
                            child: Text('Tiêu đề',
                                style: TextStyle(
                                    color: context.theme.popoverForeground))),
                      ],
                      onChanged: (value) =>
                          blogVm.updateSortFilter(sortBy: value)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                      value: blogVm.sortOrder,
                      style:
                      TextStyle(color: context.theme.textColor, fontSize: 15),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: context.theme.border)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: context.theme.border)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: context.theme.primary)),
                        filled: true,
                        fillColor: context.theme.input,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: context.theme.mutedForeground),
                      dropdownColor: context.theme.popover,
                      items: [
                        DropdownMenuItem(
                            value: 'ASC',
                            child: Text('Tăng dần',
                                style: TextStyle(
                                    color: context.theme.popoverForeground))),
                        DropdownMenuItem(
                            value: 'DESC',
                            child: Text('Giảm dần',
                                style: TextStyle(
                                    color: context.theme.popoverForeground))),
                      ],
                      onChanged: (value) =>
                          blogVm.updateSortFilter(sortOrder: value)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primary,
                    foregroundColor: context.theme.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Áp dụng')),
            )
          ],
        ),
      );
    });
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: context.theme.muted.withOpacity(0.5),
      highlightColor: context.theme.input,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.theme.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                      color: context.theme.muted,
                      borderRadius: BorderRadius.circular(8))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                        width: double.infinity,
                        height: 16.0,
                        decoration: BoxDecoration(
                            color: context.theme.muted,
                            borderRadius: BorderRadius.circular(4))),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
                    Container(
                        width: double.infinity,
                        height: 12.0,
                        decoration: BoxDecoration(
                            color: context.theme.muted,
                            borderRadius: BorderRadius.circular(4))),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 3.0)),
                    Container(
                        width: 150.0,
                        height: 12.0,
                        decoration: BoxDecoration(
                            color: context.theme.muted,
                            borderRadius: BorderRadius.circular(4))),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 6.0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                            width: 70.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                                color: context.theme.muted,
                                borderRadius: BorderRadius.circular(4))),
                        Container(
                            width: 100.0,
                            height: 10.0,
                            decoration: BoxDecoration(
                                color: context.theme.muted,
                                borderRadius: BorderRadius.circular(4))),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBlogCard(Blog blog, int index, bool isOffline) {
    String formattedDate =
    DateFormat('dd/MM/yyyy HH:mm').format(blog.updatedAt.toLocal());
    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (blog.status) {
      case 'PUBLISHED':
        statusColor = context.theme.green;
        statusText = 'Xuất bản';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'ARCHIVED':
        statusColor = context.theme.mutedForeground;
        statusText = 'Lưu trữ';
        statusIcon = Icons.archive_outlined;
        break;
      case 'DRAFT':
      default:
        statusColor = context.theme.yellow;
        statusText = 'Bản nháp';
        statusIcon = Icons.edit_note_rounded;
        break;
    }

    return Slidable(
      key: ValueKey(blog.id),
      endActionPane: isOffline
          ? null
          : ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (context) async {
              final result = await Navigator.pushNamed(
                  context, Routes.updateBlog,
                  arguments: blog.id);
              if (result == true) {}
            },
            backgroundColor: context.theme.blue,
            foregroundColor: context.theme.white,
            icon: Icons.edit_outlined,
            label: 'Sửa',
            borderRadius: BorderRadius.circular(12),
            padding: EdgeInsets.zero,
          ),
          SlidableAction(
            onPressed: (context) => _showDeleteDialog(blog),
            backgroundColor: context.theme.destructive,
            foregroundColor: context.theme.white,
            icon: Icons.delete_outline_rounded,
            label: 'Xóa',
            borderRadius: BorderRadius.circular(12),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: context.theme.border.withOpacity(0.5))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: isOffline
                ? null
                : () async {
              final result = await Navigator.pushNamed(
                  context, Routes.updateBlog,
                  arguments: blog.id);
              if (result == true) {}
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (blog.thumbnailUrl != null &&
                        blog.thumbnailUrl!.isNotEmpty)
                        ? (blog.thumbnailUrl!.toLowerCase().endsWith('.svg'))
                        ? SvgPicture.network(
                      blog.thumbnailUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholderBuilder: (context) => Container(
                          width: 70,
                          height: 70,
                          color: context.theme.muted),
                    )
                        : CachedNetworkImage(
                      imageUrl: blog.thumbnailUrl!,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                          width: 70,
                          height: 70,
                          color: context.theme.muted),
                      errorWidget: (context, url, error) => Container(
                          width: 70,
                          height: 70,
                          color: context.theme.muted.withOpacity(0.5),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: context.theme.mutedForeground,
                            size: 30,
                          )),
                    )
                        : Container(
                        width: 70,
                        height: 70,
                        color: context.theme.muted.withOpacity(0.5),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: context.theme.mutedForeground,
                          size: 30,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          blog.title,
                          style: TextStyle(
                              color: context.theme.cardForeground,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.category_outlined,
                                size: 14,
                                color: context.theme.mutedForeground),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                blog.category.name,
                                style: TextStyle(
                                    color: context.theme.mutedForeground,
                                    fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                  color: context.theme.mutedForeground
                                      .withOpacity(0.8),
                                  fontSize: 11),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Opacity(
        opacity: 0.7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 60,
              color: context.theme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Chưa có bài viết nào'
                  : 'Không tìm thấy bài viết',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: context.theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                _searchController.text.isEmpty
                    ? 'Nhấn nút "+" để thêm bài viết mới.'
                    : 'Hãy thử tìm kiếm với từ khóa khác hoặc xóa bộ lọc.',
                style:
                TextStyle(color: context.theme.mutedForeground, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Blog'),
        elevation: 0.5,
        backgroundColor: context.theme.card,
        titleTextStyle: TextStyle(
          color: context.theme.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: context.theme.textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.category_outlined,
                color: context.theme.mutedForeground),
            tooltip: "Quản lý danh mục",
            onPressed: () {
              Navigator.pushNamed(context, Routes.manageBlogCategories);
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.mutedForeground),
            tooltip: "Làm mới",
            onPressed: () =>
                context.read<BlogVm>().fetchBlogs(forceRefresh: true),
          )
        ],
      ),
      backgroundColor: context.theme.bg,
      body: Consumer<BlogVm>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildSearchSection(provider.isOffline),
              if (provider.isOffline)
                Container(
                  width: double.infinity,
                  color: context.theme.yellow.withOpacity(0.15),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: 16, color: context.theme.yellow),
                      const SizedBox(width: 8),
                      Text(
                        provider.error ?? 'Bạn đang offline. Dữ liệu có thể đã cũ.',
                        textAlign: TextAlign.center,
                        style:
                        TextStyle(color: context.theme.yellow, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              if (provider.isLoading && provider.blogs.isNotEmpty)
                LinearProgressIndicator(
                    minHeight: 2,
                    color: context.theme.primary.withOpacity(0.5)),
              Expanded(
                child: Builder(
                  builder: (innerContext) {
                    if (provider.error != null &&
                        !provider.isLoading &&
                        !provider.isLoadingMore &&
                        !provider.isOffline) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          ScaffoldMessenger.of(innerContext).showSnackBar(SnackBar(
                            content: Text("Lỗi: ${provider.error}"),
                            backgroundColor: context.theme.destructive,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            action: SnackBarAction(
                              label: "Thử lại",
                              textColor: context.theme.destructiveForeground,
                              onPressed: () =>
                                  provider.fetchBlogs(forceRefresh: true),
                            ),
                          ));
                          provider.clearError();
                        }
                      });
                    }

                    if (provider.isLoading && provider.blogs.isEmpty) {
                      return _buildShimmerList();
                    }

                    if (!provider.isLoading && provider.blogs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return RefreshIndicator(
                      color: context.theme.primary,
                      backgroundColor: context.theme.card,
                      onRefresh: () async =>
                          context.read<BlogVm>().fetchBlogs(forceRefresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 8),
                        controller: _scrollController,
                        itemCount: provider.blogs.length +
                            (provider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.blogs.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              ),
                            );
                          }
                          final blog = provider.blogs[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 30.0,
                              child: FadeInAnimation(
                                delay: const Duration(milliseconds: 100),
                                child: _buildAnimatedBlogCard(
                                    blog, index, provider.isOffline),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}