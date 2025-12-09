import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import '../../shared/widgets/widget/blog_delete_confirm.dart';
import '../../shared/widgets/common/image_display.dart';
import '../../shared/widgets/widget/category_management_sheet.dart';

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
    final snackbarService = Provider.of<SnackbarService>(
      context,
      listen: false,
    );
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
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: _buildFilterSection(),
        ),
      ),
    );
  }

  // Helper to strip HTML tags for excerpt
  String _getExcerpt(String? htmlContent, {int limit = 100}) {
    if (htmlContent == null || htmlContent.isEmpty) return '';
    // Simple regex to strip tags
    String text = htmlContent.replaceAll(
      RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true),
      ' ',
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  // Calculate read time (rough estimate: 200 words per minute)
  String _getReadTime(String? htmlContent) {
    if (htmlContent == null || htmlContent.isEmpty)
      return '1 ${AppLocalizations.of(context).translate('read_time_min')}';
    String text = htmlContent.replaceAll(RegExp(r'<[^>]*>'), ' ');
    int wordCount = text.trim().split(RegExp(r'\s+')).length;
    int minutes = (wordCount / 200).ceil();
    return '$minutes ${AppLocalizations.of(context).translate('read_time_min')}';
  }

  Widget _buildSearchSection(bool isOffline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(
                  context,
                ).translate('search_blog_hint'),
                hintStyle: TextStyle(
                  color: context.theme.mutedForeground.withOpacity(0.7),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: context.theme.primary,
                  size: 20,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: context.theme.input,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: context.theme.mutedForeground,
                          size: 20,
                        ),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
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
                  border: Border.all(color: context.theme.border),
                ),
                child: Consumer<BlogVm>(
                  builder: (context, vm, child) {
                    final bool isFilterActive =
                        vm.selectedCategoryId != null ||
                        vm.selectedStatus != null ||
                        vm.sortBy != 'createdAt' ||
                        vm.sortOrder != 'DESC';
                    return Badge(
                      isLabelVisible: isFilterActive,
                      backgroundColor: context.theme.primary,
                      smallSize: 8,
                      child: Icon(
                        Icons.filter_list_rounded,
                        color: context.theme.primary,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipGroup<T>({
    required List<T> items,
    required T? selectedItem,
    required String Function(T) labelBuilder,
    required T Function(T) valueBuilder,
    required Function(T?) onSelected,
  }) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: items.map((item) {
        final isSelected = selectedItem == valueBuilder(item);
        return ChoiceChip(
          label: Text(labelBuilder(item)),
          selected: isSelected,
          onSelected: (selected) {
            onSelected(selected ? valueBuilder(item) : null);
          },
          selectedColor: context.theme.primary,
          labelStyle: TextStyle(
            color: isSelected
                ? context.theme.primaryForeground
                : context.theme.textColor,
            fontSize: 13,
          ),
          backgroundColor: context.theme.input,
          side: BorderSide(color: context.theme.border),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        );
      }).toList(),
    );
  }

  Widget _buildFilterSection() {
    return Consumer<BlogVm>(
      builder: (context, blogVm, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('filter_sort'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: context.theme.mutedForeground,
                    ),
                    label: Text(
                      AppLocalizations.of(context).translate('reset'),
                      style: TextStyle(color: context.theme.mutedForeground),
                    ),
                    onPressed: () {
                      blogVm.resetFilters();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              // Category Filter
              Text(
                AppLocalizations.of(context).translate('blog_category_label'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (blogVm.isLoadingCategories)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (blogVm.isCategoryOffline || blogVm.categoryError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.theme.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    blogVm.categoryError ?? 'Error',
                    style: TextStyle(color: context.theme.destructive),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value:
                      blogVm.categories.any(
                        (c) => c.id == blogVm.selectedCategoryId,
                      )
                      ? blogVm.selectedCategoryId
                      : null,
                  hint: Text(
                    AppLocalizations.of(context).translate('all_categories'),
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('all_categories'),
                      ),
                    ),
                    ...blogVm.categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (val) => blogVm.updateCategoryFilter(val),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              // Status Filter
              Text(
                AppLocalizations.of(context).translate('blog_status_label'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              _buildChipGroup<String?>(
                items: [null, 'DRAFT', 'PUBLISHED', 'ARCHIVED'],
                selectedItem: blogVm.selectedStatus,
                labelBuilder: (item) {
                  if (item == null)
                    return AppLocalizations.of(context).translate('all');
                  if (item == 'DRAFT')
                    return AppLocalizations.of(
                      context,
                    ).translate('status_draft');
                  if (item == 'PUBLISHED')
                    return AppLocalizations.of(
                      context,
                    ).translate('status_published');
                  return AppLocalizations.of(
                    context,
                  ).translate('status_archived');
                },
                valueBuilder: (item) => item,
                onSelected: blogVm.updateStatusFilter,
              ),

              const SizedBox(height: 20),
              // Sort
              Text(
                AppLocalizations.of(context).translate('sort_by'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              _buildChipGroup<String>(
                items: [
                  'createdAt',
                  'publishedAt',
                  'title',
                ], // Removed updatedAt as per typical flow
                selectedItem: blogVm.sortBy,
                labelBuilder: (item) {
                  if (item == 'createdAt')
                    return AppLocalizations.of(
                      context,
                    ).translate('sort_created_at');
                  if (item == 'publishedAt')
                    return AppLocalizations.of(
                      context,
                    ).translate('sort_published_at');
                  return AppLocalizations.of(context).translate('sort_title');
                },
                valueBuilder: (item) => item,
                onSelected: (val) =>
                    blogVm.updateSortFilter(sortBy: val ?? 'createdAt'),
              ),

              const SizedBox(height: 10),
              // Order
              _buildChipGroup<String>(
                items: ['DESC', 'ASC'],
                selectedItem: blogVm.sortOrder,
                labelBuilder: (item) => item == 'DESC'
                    ? AppLocalizations.of(context).translate('descending')
                    : AppLocalizations.of(context).translate('ascending'),
                valueBuilder: (item) => item,
                onSelected: (val) =>
                    blogVm.updateSortFilter(sortOrder: val ?? 'DESC'),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primary,
                    foregroundColor: context.theme.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).translate('apply')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: context.theme.muted.withOpacity(0.5),
      highlightColor: context.theme.input,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 120,
          decoration: BoxDecoration(
            color: context.theme.card,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildBlogCard(Blog blog, bool isOffline) {
    // Determine Status Colors/Text
    Color statusColor;
    String statusText;
    switch (blog.status) {
      case 'PUBLISHED':
        statusColor = context.theme.green;
        statusText = AppLocalizations.of(context).translate('status_published');
        break;
      case 'ARCHIVED':
        statusColor = context.theme.mutedForeground;
        statusText = AppLocalizations.of(context).translate('status_archived');
        break;
      case 'DRAFT':
      default:
        statusColor = context.theme.yellow;
        statusText = AppLocalizations.of(context).translate('status_draft');
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: context.theme.border.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to Detail Page (Read Mode)
            Navigator.pushNamed(context, Routes.blogDetail, arguments: blog);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Author + Date + More Option
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12, // Slightly larger avatar
                      backgroundColor: context.theme.muted,
                      child: CommonImage(
                        imageUrl:
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(blog.authorName ?? 'A')}&background=random&size=24',
                        width: 24,
                        height: 24,
                        borderRadius: 12,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blog.authorName ?? 'Admin',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.theme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat(
                              'MMM d, yyyy',
                            ).format(blog.createdAt.toLocal()),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.theme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isOffline)
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_horiz,
                            size: 20,
                            color: context.theme.mutedForeground,
                          ),
                          padding: EdgeInsets.zero,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.pushNamed(
                                context,
                                Routes.updateBlog,
                                arguments: blog.id,
                              );
                            } else if (value == 'delete') {
                              _showDeleteDialog(blog);
                            } else if (value == 'view') {
                              Navigator.pushNamed(
                                context,
                                Routes.blogDetail,
                                arguments: blog,
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                        color: context.theme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).translate('view_blog_details'),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: context.theme.textColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).translate('edit_post'),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: context.theme.destructive,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        AppLocalizations.of(
                                          context,
                                        ).translate('delete_post'),
                                        style: TextStyle(
                                          color: context.theme.destructive,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blog.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.theme.textColor,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _getExcerpt(blog.content),
                            style: TextStyle(
                              fontSize: 13,
                              color: context.theme.mutedForeground,
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Thumbnail
                    if (blog.thumbnailUrl != null &&
                        blog.thumbnailUrl!.isNotEmpty)
                      Hero(
                        tag: 'blog_thumbnail_${blog.id}',
                        child: CommonImage(
                          imageUrl: blog.thumbnailUrl,
                          width: 90,
                          height: 90,
                          borderRadius: 12,
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Footer Tags
                Row(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.theme.input,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.theme.border),
                      ),
                      child: Text(
                        blog.category.name,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: context.theme.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Spacer(),
                    // Read Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: context.theme.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getReadTime(blog.content),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.theme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BlogVm>(
      builder: (context, blogVm, child) {
        return Scaffold(
          backgroundColor: context.theme.bg,
          appBar: AppBar(
            backgroundColor: context.theme.appBar,
            elevation: 0,
            centerTitle: true,
            title: Text(
              AppLocalizations.of(context).translate('blog_management_title'),
              style: TextStyle(
                color: context.theme.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: context.theme.white),
            actions: [
              IconButton(
                icon: Icon(Icons.category_outlined, color: context.theme.white),
                tooltip: AppLocalizations.of(
                  context,
                ).translate('manage_categories'),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CategoryManagementSheet(),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              _buildSearchSection(blogVm.isOffline),
              const SizedBox(height: 10),
              if (blogVm.isOffline)
                Container(
                  width: double.infinity,
                  color: context.theme.yellow.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 16,
                        color: context.theme.yellow,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        ).translate('offline_banner'),
                        style: TextStyle(
                          color: context.theme.yellow,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    if (!blogVm.isOffline) {
                      await blogVm.fetchBlogs(forceRefresh: true);
                    }
                  },
                  color: context.theme.primary,
                  child: blogVm.isLoading && blogVm.blogs.isEmpty
                      ? _buildShimmerList()
                      : blogVm.blogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: context.theme.mutedForeground
                                    .withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('no_blogs_yet'),
                                style: TextStyle(
                                  color: context.theme.mutedForeground,
                                  fontSize: 16,
                                ),
                              ),
                              if (!blogVm.isOffline)
                                Padding(
                                  // Add retry button if failed
                                  padding: const EdgeInsets.only(top: 16),
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        blogVm.fetchBlogs(forceRefresh: true),
                                    icon: const Icon(Icons.refresh),
                                    label: Text(
                                      AppLocalizations.of(
                                        context,
                                      ).translate('retry'),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : AnimationLimiter(
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                blogVm.blogs.length +
                                (blogVm.isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == blogVm.blogs.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  verticalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: _buildBlogCard(
                                      blogVm.blogs[index],
                                      blogVm.isOffline,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ],
          ),
          floatingActionButton: !blogVm.isOffline
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.createBlog);
                  },
                  backgroundColor: context.theme.primary,
                  foregroundColor: context.theme.primaryForeground,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}
