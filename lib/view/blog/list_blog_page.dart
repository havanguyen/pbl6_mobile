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
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.theme.border.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.theme.primary,
                    width: 1.5,
                  ),
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
                        onPressed: () {
                          _searchController.clear();
                        },
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
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                AppLocalizations.of(context).translate('blog_category_label'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              blogVm.isLoadingCategories
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : blogVm.isCategoryOffline || blogVm.categoryError != null
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.theme.destructive.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: context.theme.destructive.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            blogVm.isCategoryOffline
                                ? Icons.wifi_off_rounded
                                : Icons.error_outline_rounded,
                            color: context.theme.destructive,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              blogVm.categoryError ??
                                  AppLocalizations.of(
                                    context,
                                  ).translate('error_occurred_short'),
                              style: TextStyle(
                                color: context.theme.destructive,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                blogVm.fetchBlogCategories(forceRefresh: true),
                            child: Text(
                              AppLocalizations.of(context).translate('retry'),
                              style: TextStyle(color: context.theme.primary),
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value:
                          blogVm.categories.any(
                            (c) => c.id == blogVm.selectedCategoryId,
                          )
                          ? blogVm.selectedCategoryId
                          : null,
                      hint: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('all_categories'),
                        style: TextStyle(color: context.theme.mutedForeground),
                      ),
                      isExpanded: true,
                      style: TextStyle(
                        color: context.theme.textColor,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.theme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.theme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: context.theme.primary),
                        ),
                        filled: true,
                        fillColor: context.theme.input,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          size: 18,
                          color: context.theme.mutedForeground,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.theme.mutedForeground,
                      ),
                      dropdownColor: context.theme.popover,
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).translate('all_categories'),
                            style: TextStyle(
                              color: context.theme.mutedForeground,
                            ),
                          ),
                        ),
                        ...blogVm.categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(
                              category.name,
                              style: TextStyle(
                                color: context.theme.popoverForeground,
                              ),
                            ),
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
                          return AppLocalizations.of(context).translate(
                            'error_load_specialty_profile',
                          ); // Reusing generic load error
                        }
                        return null;
                      },
                    ),
              const SizedBox(height: 20),
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
                  switch (item) {
                    case 'DRAFT':
                      return AppLocalizations.of(
                        context,
                      ).translate('status_draft');
                    case 'PUBLISHED':
                      return AppLocalizations.of(
                        context,
                      ).translate('status_published');
                    case 'ARCHIVED':
                      return AppLocalizations.of(
                        context,
                      ).translate('status_archived');
                    default:
                      return AppLocalizations.of(context).translate('all');
                  }
                },
                valueBuilder: (item) => item,
                onSelected: (value) {
                  blogVm.updateStatusFilter(value);
                },
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).translate('sort_by'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              _buildChipGroup<String>(
                items: ['createdAt', 'updatedAt', 'publishedAt', 'title'],
                selectedItem: blogVm.sortBy,
                labelBuilder: (item) {
                  switch (item) {
                    case 'createdAt':
                      return AppLocalizations.of(
                        context,
                      ).translate('sort_created_at');
                    case 'updatedAt':
                      return AppLocalizations.of(
                        context,
                      ).translate('sort_updated_at');
                    case 'publishedAt':
                      return AppLocalizations.of(
                        context,
                      ).translate('sort_published_at');
                    case 'title':
                      return AppLocalizations.of(
                        context,
                      ).translate('sort_title');
                    default:
                      return '';
                  }
                },
                valueBuilder: (item) => item,
                onSelected: (value) {
                  blogVm.updateSortFilter(sortBy: value ?? 'createdAt');
                },
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).translate('order_label'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              _buildChipGroup<String>(
                items: ['DESC', 'ASC'],
                selectedItem: blogVm.sortOrder,
                labelBuilder: (item) {
                  switch (item) {
                    case 'DESC':
                      return AppLocalizations.of(
                        context,
                      ).translate('descending');
                    case 'ASC':
                      return AppLocalizations.of(
                        context,
                      ).translate('ascending');
                    default:
                      return '';
                  }
                },
                valueBuilder: (item) => item,
                onSelected: (value) {
                  blogVm.updateSortFilter(sortOrder: value ?? 'DESC');
                },
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
                width: 80.0,
                height: 80.0,
                decoration: BoxDecoration(
                  color: context.theme.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
                    Container(
                      width: double.infinity,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: context.theme.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 3.0)),
                    Container(
                      width: 150.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: context.theme.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 6.0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 70.0,
                          height: 10.0,
                          decoration: BoxDecoration(
                            color: context.theme.muted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Container(
                          width: 100.0,
                          height: 10.0,
                          decoration: BoxDecoration(
                            color: context.theme.muted,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBlogCard(Blog blog, int index, bool isOffline) {
    String formattedDate = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(blog.updatedAt.toLocal());
    Color statusColor;
    String statusText;
    IconData statusIcon;
    switch (blog.status) {
      case 'PUBLISHED':
        statusColor = context.theme.green;
        statusText = AppLocalizations.of(context).translate('status_published');
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case 'ARCHIVED':
        statusColor = context.theme.mutedForeground;
        statusText = AppLocalizations.of(context).translate('status_archived');
        statusIcon = Icons.archive_outlined;
        break;
      case 'DRAFT':
      default:
        statusColor = context.theme.yellow;
        statusText = AppLocalizations.of(context).translate('status_draft');
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
                      context,
                      Routes.updateBlog,
                      arguments: blog.id,
                    );
                    if (result == true) {}
                  },
                  backgroundColor: context.theme.blue,
                  foregroundColor: context.theme.white,
                  icon: Icons.edit_outlined,
                  label: AppLocalizations.of(context).translate('edit'),
                  borderRadius: BorderRadius.circular(12),
                  padding: EdgeInsets.zero,
                ),
                SlidableAction(
                  onPressed: (context) => _showDeleteDialog(blog),
                  backgroundColor: context.theme.destructive,
                  foregroundColor: context.theme.white,
                  icon: Icons.delete_outline_rounded,
                  label: AppLocalizations.of(context).translate('delete'),
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
          side: BorderSide(color: context.theme.border.withOpacity(0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isOffline
              ? null
              : () async {
                  final result = await Navigator.pushNamed(
                    context,
                    Routes.updateBlog,
                    arguments: blog.id,
                  );
                  if (result == true) {}
                },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'blog_thumbnail_${blog.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        (blog.thumbnailUrl != null &&
                            blog.thumbnailUrl!.isNotEmpty)
                        ? (blog.thumbnailUrl!.toLowerCase().endsWith('.svg'))
                              ? SvgPicture.network(
                                  blog.thumbnailUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (context) => Container(
                                    width: 80,
                                    height: 80,
                                    color: context.theme.muted,
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: blog.thumbnailUrl!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    width: 80,
                                    height: 80,
                                    color: context.theme.muted,
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        width: 80,
                                        height: 80,
                                        color: context.theme.muted.withOpacity(
                                          0.5,
                                        ),
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          color: context.theme.mutedForeground,
                                          size: 30,
                                        ),
                                      ),
                                )
                        : Container(
                            width: 80,
                            height: 80,
                            color: context.theme.muted.withOpacity(0.5),
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: context.theme.mutedForeground,
                              size: 30,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Hero(
                              tag: 'blog_title_${blog.id}',
                              child: Material(
                                type: MaterialType.transparency,
                                child: Text(
                                  blog.title,
                                  style: TextStyle(
                                    color: context.theme.cardForeground,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.category_outlined,
                                  size: 14,
                                  color: context.theme.mutedForeground,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    blog.category.name,
                                    style: TextStyle(
                                      color: context.theme.mutedForeground,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: context.theme.mutedForeground
                                    .withOpacity(0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                  ? AppLocalizations.of(context).translate('no_blogs_yet')
                  : AppLocalizations.of(context).translate('no_blogs_found'),
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
                    ? AppLocalizations.of(
                        context,
                      ).translate('add_new_blog_hint')
                    : AppLocalizations.of(
                        context,
                      ).translate('try_search_again'),
                style: TextStyle(
                  color: context.theme.mutedForeground,
                  fontSize: 13,
                ),
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
    final blogVm = context.watch<BlogVm>();
    final isOffline = blogVm.isOffline;

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).translate('blog_management_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.category_rounded, color: context.theme.white),
            tooltip: AppLocalizations.of(
              context,
            ).translate('manage_blog_categories'),
            onPressed: isOffline
                ? null
                : () {
                    Navigator.pushNamed(context, Routes.manageBlogCategories);
                  },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.white),
            onPressed: () => blogVm.fetchBlogs(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(isOffline),
          if (isOffline)
            Container(
              width: double.infinity,
              color: context.theme.yellow,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                AppLocalizations.of(context).translate('offline_banner'),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.theme.popover),
              ),
            ),
          if (blogVm.isLoading && blogVm.blogs.isNotEmpty)
            const LinearProgressIndicator(),
          Expanded(
            child: Builder(
              builder: (context) {
                if (blogVm.isLoading && blogVm.blogs.isEmpty) {
                  return _buildShimmerList();
                }

                if (blogVm.error != null && blogVm.blogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: context.theme.destructive,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${AppLocalizations.of(context).translate('error_occurred')}${blogVm.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.theme.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              blogVm.fetchBlogs(forceRefresh: true),
                          child: Text(
                            AppLocalizations.of(context).translate('retry'),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (blogVm.blogs.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async => blogVm.fetchBlogs(forceRefresh: true),
                  child: ListView.builder(
                    key: const ValueKey('blog_list_scroll_view'),
                    controller: _scrollController,
                    itemCount:
                        blogVm.blogs.length + (blogVm.isLoadingMore ? 1 : 0),
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
                            child: _buildAnimatedBlogCard(
                              blogVm.blogs[index],
                              index,
                              isOffline,
                            ),
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
      ),
      floatingActionButton: isOffline
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  Routes.createBlog,
                );
                if (result == true) {
                  // Refresh list if needed
                }
              },
              backgroundColor: context.theme.primary,
              child: Icon(Icons.add, color: context.theme.primaryForeground),
            ),
    );
  }
}
