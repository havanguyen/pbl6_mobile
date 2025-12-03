import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/quill_edittor.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'doctor_form.dart';

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
  State<BlogForm> createState() => _BlogFormState();
}

class _BlogFormState extends State<BlogForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late quill.QuillController _contentController;
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
    _selectedCategory = context.read<BlogVm>().categories.firstWhere(
      (cat) => cat.id == widget.initialData?.category.id,
      orElse: () => context.read<BlogVm>().categories.isNotEmpty
          ? context.read<BlogVm>().categories.first
          : BlogCategory(id: '', name: 'Loading...', slug: ''),
    );

    if (widget.initialData != null &&
        !context.read<BlogVm>().categories.any(
          (c) => c.id == _selectedCategory?.id,
        )) {
      _selectedCategory = null;
    }

    _selectedStatus = widget.isUpdate
        ? (widget.initialData?.status ?? 'DRAFT')
        : null;
    _initialThumbnailUrl = widget.initialData?.thumbnailUrl;

    _contentController = _initializeQuillController(
      widget.initialData?.content,
    );

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
            if (mounted &&
                widget.initialData != null &&
                (_selectedCategory == null || _selectedCategory!.id.isEmpty)) {
              BlogCategory? newSelectedCategory;
              try {
                newSelectedCategory = blogVm.categories.firstWhere(
                  (cat) => cat.id == widget.initialData!.category.id,
                );
              } catch (e) {
                newSelectedCategory = blogVm.categories.isNotEmpty
                    ? blogVm.categories.first
                    : null;
              }
              setState(() {
                _selectedCategory = newSelectedCategory;
              });
            }
          });
        }
        _animationController.forward();
      }
    });
  }

  quill.QuillController _initializeQuillController(String? content) {
    if (content != null && content.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(content);
        final doc = quill.Document.fromJson(deltaJson);
        return quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        try {
          final plainText = content
              .replaceAll('<br>', '\n')
              .replaceAll(RegExp(r'<[^>]*>'), '');
          final doc = quill.Document()..insert(0, plainText);
          return quill.QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (plainTextError) {
          print(
            "Error initializing Quill with non-JSON content: $plainTextError",
          );
          return quill.QuillController.basic();
        }
      }
    }
    return quill.QuillController.basic();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<BlogVm>(
          context,
          listen: false,
        ).resetThumbnailState(notify: false);
      }
    });
    super.dispose();
  }

  Future<bool> _submitForm() async {
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
      String? getQuillJsonOrNull(quill.QuillController controller) {
        if (controller.document.isEmpty() ||
            controller.document.toPlainText().trim().isEmpty) {
          return null;
        }
        try {
          return jsonEncode(controller.document.toDelta().toJson());
        } catch (e) {
          print("Error encoding Quill JSON: $e");
          return controller.document.toPlainText().trim();
        }
      }

      final jsonContent = getQuillJsonOrNull(_contentController);
      if (jsonContent == null) {
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
          content: jsonContent,
          categoryId: _selectedCategory!.id,
          status: _selectedStatus,
          thumbnailUrl: currentThumbnailUrl,
        );
      } else {
        success = await blogVm.createBlog(
          title: _titleController.text.trim(),
          content: jsonContent,
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

  Widget _buildAnimatedFormField({required Widget child, required int index}) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2 * index, 1.0, curve: Curves.easeOutCubic),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Interval(0.2 * index, 1.0, curve: Curves.easeOutCubic),
              ),
            ),
        child: child,
      ),
    );
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
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print("Error loading selected file image: $error");
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
      imageWidget = CachedNetworkImage(
        imageUrl: displayUrl,
        key: ValueKey(displayUrl),
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: theme.mutedForeground,
            size: 40,
          ),
        ),
      );
    } else {
      imageWidget = Center(
        child: Icon(
          Icons.image_search_rounded,
          key: const ValueKey('placeholder'),
          size: 50,
          color: theme.mutedForeground.withOpacity(0.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).translate('blog_thumbnail_label'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  _imageFileError != null || blogVm.thumbnailUploadError != null
                  ? theme.destructive
                  : theme.border,
              width: 0.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: imageWidget,
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isUploading
                          ? null
                          : () {
                              setState(() {
                                _imageFileError = null;
                              });
                              blogVm.pickThumbnailImage();
                            },
                    ),
                  ),
                ),
                if (isUploading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                if (!isUploading &&
                    (selectedFile != null ||
                        (displayUrl != null && displayUrl.isNotEmpty)))
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.destructive.withOpacity(0.8),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: theme.destructiveForeground,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _initialThumbnailUrl = null;
                                _imageFileError = null;
                              });
                              context.read<BlogVm>().resetThumbnailState();
                            },
                            tooltip: AppLocalizations.of(
                              context,
                            ).translate('remove_thumbnail'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: theme.primary.withOpacity(0.8),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: theme.primaryForeground,
                              size: 18,
                            ),
                            onPressed: () {
                              setState(() {
                                _imageFileError = null;
                              });
                              blogVm.pickThumbnailImage();
                            },
                            tooltip: AppLocalizations.of(
                              context,
                            ).translate('change_thumbnail'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!isUploading &&
                    selectedFile == null &&
                    (displayUrl == null || displayUrl.isEmpty))
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 20,
                      ),
                      label: Text(
                        AppLocalizations.of(
                          context,
                        ).translate('select_thumbnail'),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: theme.primaryForeground,
                        backgroundColor: theme.primary.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _imageFileError = null;
                        });
                        blogVm.pickThumbnailImage();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_imageFileError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              _imageFileError!,
              style: TextStyle(color: theme.destructive, fontSize: 13),
            ),
          ),
        ] else if (blogVm.thumbnailUploadError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              blogVm.thumbnailUploadError!,
              style: TextStyle(color: theme.destructive, fontSize: 13),
            ),
          ),
        ],
      ],
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
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.border, width: 0.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: QuillEditor(
                  label: AppLocalizations.of(
                    context,
                  ).translate('blog_content_label'),
                  controller: _contentController,
                  isReadOnly: false,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildAnimatedFormField(
              index: animationIndex++,
              child: Center(
                child: AnimatedSubmitButton(
                  onSubmit: _submitForm,
                  idleText: widget.isUpdate
                      ? AppLocalizations.of(context).translate('save')
                      : AppLocalizations.of(context).translate('create'),
                  loadingText:
                      '${AppLocalizations.of(context).translate('processing')}...',
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
