import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/blog_category_delete_dialog.dart';
import 'package:pbl6mobile/shared/widgets/widget/blog_category_form_dialog.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class ManageCategoriesPage extends StatelessWidget {
  const ManageCategoriesPage({super.key});

  void _showCategoryFormDialog(BuildContext context, {BlogCategory? category}) {
    final blogVm = context.read<BlogVm>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: blogVm,
        child: BlogCategoryFormDialog(
          initialData: category,
          snackbarService: context.read<SnackbarService>(),
        ),
      ),
    );
  }

  void _showCategoryDeleteDialog(BuildContext context, BlogCategory category) {
    final blogVm = context.read<BlogVm>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeNotifierProvider.value(
        value: blogVm,
        child: BlogCategoryDeleteDialog(
          category: category,
          snackbarService: context.read<SnackbarService>(),
        ),
      ),
    );
  }

  Widget _buildShimmerList(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.theme.muted.withOpacity(0.5),
      highlightColor: context.theme.input,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 8,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: context.theme.muted,
              radius: 20,
            ),
            title: Container(
              height: 16,
              decoration: BoxDecoration(
                color: context.theme.muted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            subtitle: Container(
              height: 12,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: context.theme.muted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.7,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 60,
              color: context.theme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).translate('no_categories_yet'),
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
                AppLocalizations.of(context).translate('add_new_category_hint'),
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

  Widget _buildCategoryCard(
    BuildContext context,
    BlogCategory category,
    int index,
  ) {
    final theme = context.theme;
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 375),
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          delay: const Duration(milliseconds: 100),
          child: Slidable(
            key: ValueKey(category.id),
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.5,
              children: [
                SlidableAction(
                  onPressed: (context) =>
                      _showCategoryFormDialog(context, category: category),
                  backgroundColor: theme.blue,
                  foregroundColor: theme.white,
                  icon: Icons.edit_outlined,
                  label: AppLocalizations.of(context).translate('edit'),
                  borderRadius: BorderRadius.circular(12),
                ),
                SlidableAction(
                  onPressed: (context) =>
                      _showCategoryDeleteDialog(context, category),
                  backgroundColor: theme.destructive,
                  foregroundColor: theme.white,
                  icon: Icons.delete_outline_rounded,
                  label: AppLocalizations.of(context).translate('delete'),
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.border.withOpacity(0.5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () =>
                    _showCategoryFormDialog(context, category: category),
                leading: CircleAvatar(
                  backgroundColor: theme.primary.withOpacity(0.1),
                  foregroundColor: theme.primary,
                  child: const Icon(Icons.label_outline_rounded, size: 22),
                ),
                title: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
                subtitle: Text(
                  category.description ??
                      AppLocalizations.of(context).translate('none'),
                  style: TextStyle(color: theme.mutedForeground),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final blogVm = context.watch<BlogVm>();

    Widget buildBody() {
      if (blogVm.isLoadingCategories && blogVm.categories.isEmpty) {
        return _buildShimmerList(context);
      }
      if (blogVm.categoryError != null && blogVm.categories.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "${AppLocalizations.of(context).translate('error')}: ${blogVm.categoryError!}",
              style: TextStyle(color: theme.destructive),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      if (blogVm.categories.isEmpty) {
        return _buildEmptyState(context);
      }
      return RefreshIndicator(
        color: theme.primary,
        backgroundColor: theme.card,
        onRefresh: () => blogVm.fetchBlogCategories(forceRefresh: true),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: blogVm.categories.length,
          itemBuilder: (context, index) {
            final category = blogVm.categories[index];
            return _buildCategoryCard(context, category, index);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('manage_blog_categories'),
        ),
        elevation: 0.5,
        backgroundColor: theme.card,
        titleTextStyle: TextStyle(
          color: theme.textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.mutedForeground),
            tooltip: AppLocalizations.of(context).translate('reset'),
            onPressed: () => blogVm.fetchBlogCategories(forceRefresh: true),
          ),
        ],
      ),
      backgroundColor: theme.bg,
      body: buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryFormDialog(context),
        backgroundColor: theme.primary,
        child: Icon(Icons.add, color: theme.primaryForeground),
        tooltip: AppLocalizations.of(
          context,
        ).translate('create_category_title'),
      ),
    );
  }
}
