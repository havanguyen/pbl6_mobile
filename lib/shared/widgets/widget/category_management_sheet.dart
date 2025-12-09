import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';

class CategoryManagementSheet extends StatefulWidget {
  const CategoryManagementSheet({super.key});

  @override
  State<CategoryManagementSheet> createState() =>
      _CategoryManagementSheetState();
}

class _CategoryManagementSheetState extends State<CategoryManagementSheet> {
  // Use a dialog for Create/Edit to keep the list clean
  Future<void> _showCategoryDialog({BlogCategory? category}) async {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(
      text: category?.description ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEditing
              ? AppLocalizations.of(context).translate('edit_category')
              : AppLocalizations.of(context).translate('create_category'),
          style: TextStyle(
            color: context.theme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: !isEditing,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('name'),
                labelStyle: TextStyle(color: context.theme.mutedForeground),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.theme.mutedForeground.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: TextStyle(color: context.theme.textColor),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).translate('description'),
                labelStyle: TextStyle(color: context.theme.mutedForeground),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.theme.mutedForeground.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: context.theme.mutedForeground),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final vm = context.read<BlogVm>();
              bool success;

              // We can't await Future here easily without managing loading state manually in dialog
              // Or we just close dialog and let VM handle it?
              // Better to await so we can close dialog only on success.
              // But standard Dialog doesn't have local loading state unless we make it a Stateful Widget.
              // For simplicity, we assume generic VM loading overlay isn't blocking this dialog.
              // Actually, `category_management_sheet` is below.

              Navigator.pop(
                context,
              ); // Close dialog first to show progress on sheet if needed?
              // Or better: Use VM call.

              if (isEditing) {
                success = await vm.updateBlogCategory(
                  category.id,
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                );
              } else {
                success = await vm.createBlogCategory(
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                );
              }

              // Feedback is handled by VM/UI listeners, but we can show snackbar here if we want extra confirmation
              if (!success && mounted) {
                // Error handling usually in VM
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primary,
              foregroundColor: context.theme.primaryForeground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(AppLocalizations.of(context).translate('save')),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String categoryId) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context).translate('confirm_delete'),
          style: TextStyle(
            color: context.theme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).translate('confirm_delete_category'),
              style: TextStyle(color: context.theme.mutedForeground),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('password'),
                labelStyle: TextStyle(color: context.theme.mutedForeground),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.theme.mutedForeground.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.theme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: context.theme.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              Navigator.pop(context);

              final success = await context.read<BlogVm>().deleteBlogCategory(
                categoryId,
                password: passwordController.text,
              );

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('delete_category_success'),
                      ),
                      backgroundColor: context.theme.green,
                    ),
                  );
                } else {
                  final error = context.read<BlogVm>().categoryError;
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: context.theme.destructive,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: TextStyle(
                color: context.theme.destructive,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine height: 70% of screen height
    final height = MediaQuery.of(context).size.height * 0.7;

    return Container(
      height: height,
      padding: const EdgeInsets.only(top: 16), // Padding top
      decoration: BoxDecoration(
        color: context.theme.bg, // Use background color
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.theme.mutedForeground.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).translate('manage_categories'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: context.theme.textColor,
                  ),
                ),
                // Close Button
                Container(
                  decoration: BoxDecoration(
                    color: context.theme.muted.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: context.theme.textColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: context.theme.mutedForeground.withOpacity(0.1)),

          // Content
          Expanded(
            child: Consumer<BlogVm>(
              builder: (context, vm, child) {
                if (vm.isLoadingCategories && vm.categories.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vm.categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 64,
                          color: context.theme.mutedForeground.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).translate('no_categories'),
                          style: TextStyle(
                            color: context.theme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.categories.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final category = vm.categories[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: context.theme.card,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              0.04,
                            ), // soft shadow
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          category.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: context.theme.textColor,
                          ),
                        ),
                        subtitle:
                            category.description != null &&
                                category.description!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  category.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.theme.mutedForeground,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Separator
                            Container(
                              height: 24,
                              width: 1,
                              color: context.theme.mutedForeground.withOpacity(
                                0.2,
                              ),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            InkWell(
                              onTap: () =>
                                  _showCategoryDialog(category: category),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: context.theme.primary,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _showDeleteDialog(category.id),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: context.theme.destructive,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Action
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(),
                icon: const Icon(Icons.add),
                label: Text(
                  AppLocalizations.of(context).translate('add_new_category'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primary,
                  foregroundColor: context.theme.primaryForeground,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: context.theme.primary.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
