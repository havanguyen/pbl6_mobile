import 'dart:io';

import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/shared/widgets/common/image_display.dart'; // Add CommonImage import

class BlogForm extends StatefulWidget {
  final bool isUpdate;
  final String? blogId;
  final Blog? initialData;

  const BlogForm({
    super.key,
    required this.isUpdate,
    required this.blogId,
    this.initialData,
  });

  @override
  State<BlogForm> createState() => BlogFormState();
}

class BlogFormState extends State<BlogForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late HtmlEditorController _contentController;
  BlogCategory? _selectedCategory;
  String? _selectedStatus;
  String? _initialThumbnailUrl;
  String? _imageFileError;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.initialData?.title ?? '',
    );
    _contentController = HtmlEditorController();

    // Initial category selection logic
    final blogVm = context.read<BlogVm>();
    if (blogVm.categories.isNotEmpty) {
      if (widget.initialData != null) {
        try {
          _selectedCategory = blogVm.categories.firstWhere(
            (cat) => cat.id == widget.initialData!.category.id,
          );
        } catch (_) {
          _selectedCategory = blogVm.categories.first;
        }
      } else {
        _selectedCategory = blogVm.categories.first;
      }
    } else {
      _selectedCategory = null;
    }

    _selectedStatus = widget.isUpdate
        ? (widget.initialData?.status ?? 'DRAFT')
        : null;
    _initialThumbnailUrl = widget.initialData?.thumbnailUrl;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    context.read<BlogVm>().resetThumbnailState(notify: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final blogVm = context.read<BlogVm>();
        if (blogVm.categories.isEmpty && !blogVm.isLoadingCategories) {
          blogVm.fetchBlogCategories().then((_) {
            if (mounted) {
              // Update category after fetch if currently null or empty
              if (_selectedCategory == null || _selectedCategory!.id.isEmpty) {
                BlogCategory? newSelectedCategory;
                if (widget.initialData != null) {
                  try {
                    newSelectedCategory = blogVm.categories.firstWhere(
                      (cat) => cat.id == widget.initialData!.category.id,
                    );
                  } catch (_) {
                    if (blogVm.categories.isNotEmpty)
                      newSelectedCategory = blogVm.categories.first;
                  }
                } else {
                  // For Create Mode, default to first category
                  if (blogVm.categories.isNotEmpty)
                    newSelectedCategory = blogVm.categories.first;
                }

                if (newSelectedCategory != null) {
                  setState(() {
                    _selectedCategory = newSelectedCategory;
                  });
                }
              }
            }
          });
        }
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _animationController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if context is still valid
        try {
          Provider.of<BlogVm>(
            context,
            listen: false,
          ).resetThumbnailState(notify: false);
        } catch (_) {}
      }
    });
    super.dispose();
  }

  Widget _buildAnimatedFormField({required Widget child, required int index}) {
    if (!mounted) return child;
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          (0.1 * index).clamp(0.0, 1.0),
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  (0.1 * index).clamp(0.0, 1.0),
                  1.0,
                  curve: Curves.easeOutCubic,
                ),
              ),
            ),
        child: child,
      ),
    );
  }

  Future<bool> submitForm() async {
    setState(() {
      _imageFileError = null;
    });
    if (_formKey.currentState!.validate()) {
      final blogVm = context.read<BlogVm>();
      if (blogVm.isUploadingThumbnail || blogVm.isUpdatingEntity) {
        return false;
      }

      if (_selectedCategory == null || _selectedCategory!.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('category_required'),
            ),
            backgroundColor: context.theme.destructive,
          ),
        );
        return false;
      }

      final content = await _contentController.getText();

      if (content.isEmpty || content.trim() == '<p><br></p>') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('content_required'),
            ),
            backgroundColor: context.theme.destructive,
          ),
        );
        return false;
      }

      bool success;
      final messenger = ScaffoldMessenger.of(context);
      final currentThumbnailUrl = _initialThumbnailUrl;

      if (widget.isUpdate) {
        success = await blogVm.updateBlog(
          widget.blogId!,
          title: _titleController.text.trim(),
          content: content,
          categoryId: _selectedCategory!.id,
          status: _selectedStatus,
          thumbnailUrl: currentThumbnailUrl,
        );
      } else {
        success = await blogVm.createBlog(
          title: _titleController.text.trim(),
          content: content,
          categoryId: _selectedCategory!.id,
          thumbnailUrl: currentThumbnailUrl,
        );
      }

      if (mounted) {
        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                widget.isUpdate
                    ? AppLocalizations.of(
                        context,
                      ).translate('update_blog_success')
                    : AppLocalizations.of(
                        context,
                      ).translate('create_blog_success'),
              ),
              backgroundColor: context.theme.green,
              duration: const Duration(seconds: 2),
            ),
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) Navigator.of(context).pop(true);
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                blogVm.error ??
                    (widget.isUpdate
                        ? AppLocalizations.of(
                            context,
                          ).translate('update_blog_failed')
                        : AppLocalizations.of(
                            context,
                          ).translate('create_blog_failed')),
              ),
              backgroundColor: context.theme.destructive,
            ),
          );
          blogVm.clearError();
          blogVm.clearCategoryError();
        }
      }
      return success;
    }
    return false;
  }

  Widget _buildThumbnailPicker(BlogVm blogVm, CustomThemeExtension theme) {
    File? selectedFile = blogVm.selectedThumbnailFile;
    String? displayUrl = blogVm.uploadedThumbnailUrl ?? _initialThumbnailUrl;
    bool isUploading = blogVm.isUploadingThumbnail;

    Widget imageWidget;
    if (selectedFile != null) {
      imageWidget = Image.file(
        selectedFile,
        key: ValueKey(selectedFile.path),
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _imageFileError = AppLocalizations.of(
                  context,
                ).translate('thumbnail_error');
              });
              context.read<BlogVm>().resetThumbnailState();
            }
          });
          return Center(
            child: Icon(
              Icons.error_outline,
              color: theme.destructive,
              size: 40,
            ),
          );
        },
      );
    } else if (displayUrl != null && displayUrl.isNotEmpty) {
      imageWidget = CommonImage(
        imageUrl: displayUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: theme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).translate('select_thumbnail'),
            style: TextStyle(
              color: theme.mutedForeground,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined, size: 20, color: theme.primary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).translate('blog_thumbnail_label'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: isUploading
              ? null
              : () {
                  setState(() {
                    _imageFileError = null;
                  });
                  blogVm.pickThumbnailImage();
                },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _imageFileError != null ||
                        blogVm.thumbnailUploadError != null
                    ? theme.destructive
                    : ((displayUrl == null && selectedFile == null)
                          ? theme.primary.withOpacity(0.5)
                          : theme.border),
                width: (displayUrl == null && selectedFile == null) ? 1.5 : 1,
                style: BorderStyle.solid,
              ),
              boxShadow: (displayUrl != null || selectedFile != null)
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05), // Fixed shadow
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                imageWidget,
                if (isUploading)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                if (!isUploading &&
                    (selectedFile != null ||
                        (displayUrl != null && displayUrl.isNotEmpty)))
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildActionButton(
                          theme,
                          icon: Icons.edit,
                          color: theme.primary,
                          onTap: () => blogVm.pickThumbnailImage(),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          theme,
                          icon: Icons.delete_outline,
                          color: theme.destructive,
                          onTap: () {
                            setState(() {
                              _initialThumbnailUrl = null;
                              _imageFileError = null;
                            });
                            context.read<BlogVm>().resetThumbnailState();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (_imageFileError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _imageFileError!,
              style: TextStyle(color: theme.destructive, fontSize: 13),
            ),
          ),
        ] else if (blogVm.thumbnailUploadError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              blogVm.thumbnailUploadError!,
              style: TextStyle(color: theme.destructive, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    CustomThemeExtension theme, {
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.card.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final blogVm = context.watch<BlogVm>();
    int animationIndex = 0;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedFormField(
              index: animationIndex++,
              child: TextFormField(
                controller: _titleController,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  ).translate('blog_title_label'),
                  labelStyle: TextStyle(color: theme.mutedForeground),
                  prefixIcon: Icon(
                    Icons.title_rounded,
                    color: theme.primary,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: theme.input,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(
                      context,
                    ).translate('title_required');
                  }
                  if (value.trim().length < 10 || value.trim().length > 500) {
                    return AppLocalizations.of(
                      context,
                    ).translate('title_length_error');
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            _buildAnimatedFormField(
              index: animationIndex++,
              child: blogVm.isLoadingCategories
                  ? Container(
                      height: 58,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.input,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 20,
                            color: theme.mutedForeground,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${AppLocalizations.of(context).translate('loading_list')}...',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<BlogCategory>(
                      value: _selectedCategory,
                      hint: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('blog_category_label'),
                        style: TextStyle(color: theme.mutedForeground),
                      ),
                      isExpanded: true,
                      style: TextStyle(color: theme.textColor, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        ).translate('blog_category_label'),
                        labelStyle: TextStyle(color: theme.mutedForeground),
                        prefixIcon: Icon(
                          Icons.category_outlined,
                          color: theme.primary,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.input,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.mutedForeground,
                      ),
                      dropdownColor: theme.popover,
                      items: blogVm.categories.map((category) {
                        return DropdownMenuItem<BlogCategory>(
                          value: category,
                          child: Text(
                            category.name,
                            style: TextStyle(color: theme.popoverForeground),
                          ),
                        );
                      }).toList(),
                      onChanged: blogVm.categories.isEmpty
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                      validator: (value) => (value == null || value.id.isEmpty)
                          ? AppLocalizations.of(
                              context,
                            ).translate('category_required')
                          : null,
                    ),
            ),
            if (blogVm.categoryError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12),
                child: Text(
                  blogVm.categoryError!,
                  style: TextStyle(color: theme.destructive, fontSize: 12),
                ),
              ),
            const SizedBox(height: 20),
            if (widget.isUpdate) ...[
              _buildAnimatedFormField(
                index: animationIndex++,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  style: TextStyle(color: theme.textColor, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).translate('blog_status_label'),
                    labelStyle: TextStyle(color: theme.mutedForeground),
                    prefixIcon: Icon(
                      Icons.toggle_on_outlined,
                      color: theme.primary,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: theme.input,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.mutedForeground,
                  ),
                  dropdownColor: theme.popover,
                  items: ['DRAFT', 'PUBLISHED', 'ARCHIVED'].map((status) {
                    String statusText;
                    Color statusColor;
                    switch (status) {
                      case 'PUBLISHED':
                        statusText = AppLocalizations.of(
                          context,
                        ).translate('status_published');
                        statusColor = theme.green;
                        break;
                      case 'ARCHIVED':
                        statusText = AppLocalizations.of(
                          context,
                        ).translate('status_archived');
                        statusColor = theme.mutedForeground;
                        break;
                      case 'DRAFT':
                      default:
                        statusText = AppLocalizations.of(
                          context,
                        ).translate('status_draft');
                        statusColor = theme.yellow;
                        break;
                    }
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: statusColor),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: TextStyle(color: theme.popoverForeground),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                  validator: (value) => value == null
                      ? AppLocalizations.of(
                          context,
                        ).translate('status_required')
                      : null,
                ),
              ),
              const SizedBox(height: 20),
            ],
            _buildAnimatedFormField(
              index: animationIndex++,
              child: _buildThumbnailPicker(blogVm, theme),
            ),
            const SizedBox(height: 24),
            _buildAnimatedFormField(
              index: animationIndex++,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    ).translate('blog_content_label'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 500,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.border),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.card,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: HtmlEditor(
                      controller: _contentController,
                      htmlEditorOptions: HtmlEditorOptions(
                        hint: "Start typing...",
                        initialText: widget.initialData?.content ?? '',
                        darkMode:
                            Theme.of(context).brightness == Brightness.dark,
                        shouldEnsureVisible: true,
                        //adjustHeightForKeyboard: false,
                      ),
                      htmlToolbarOptions: HtmlToolbarOptions(
                        toolbarPosition: ToolbarPosition.aboveEditor,
                        toolbarType: ToolbarType.nativeScrollable,
                        dropdownBackgroundColor: theme.popover,
                        dropdownBoxDecoration: BoxDecoration(
                          color: theme.popover,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        buttonColor: theme.textColor,
                        buttonFillColor: theme.card,
                        textStyle: TextStyle(
                          color: theme.textColor,
                          fontSize: 16,
                        ),
                      ),
                      otherOptions: OtherOptions(
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.input,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
