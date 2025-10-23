import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/model/entities/blog_category.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/quill_edittor.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:provider/provider.dart';
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

class _BlogFormState extends State<BlogForm> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late quill.QuillController _contentController;
  BlogCategory? _selectedCategory;
  String? _selectedStatus;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.initialData?.title ?? '');
    _selectedCategory = context.read<BlogVm>().categories.firstWhere(
          (cat) => cat.id == widget.initialData?.category.id,
      orElse: () => context.read<BlogVm>().categories.isNotEmpty
          ? context.read<BlogVm>().categories.first
          : BlogCategory(id: '', name: 'Loading...', slug: ''),
    );

    if (widget.initialData != null && !context.read<BlogVm>().categories.any((c) => c.id == _selectedCategory?.id)) {
      _selectedCategory = null;
    }

    _selectedStatus = widget.isUpdate ? (widget.initialData?.status ?? 'DRAFT') : null;

    _contentController = _initializeQuillController(widget.initialData?.content);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final blogVm = context.read<BlogVm>();
        if (blogVm.categories.isEmpty && !blogVm.isLoadingCategories) {
          blogVm.fetchBlogCategories().then((_) {
            if (widget.initialData != null && _selectedCategory?.id == '') {
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

              if (mounted) {
                setState(() {
                  _selectedCategory = newSelectedCategory;
                });
              }
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
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      } catch (e) {
        try {
          final plainText = content
              .replaceAll('<br>', '\n')
              .replaceAll(RegExp(r'<[^>]*>'), '');
          final doc = quill.Document()..insert(0, plainText);
          return quill.QuillController(
              document: doc, selection: const TextSelection.collapsed(offset: 0));
        } catch (plainTextError) {
          print("Error initializing Quill with non-JSON content: $plainTextError");
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
    super.dispose();
  }

  Future<bool> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null || _selectedCategory!.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Vui lòng chọn danh mục hợp lệ'), backgroundColor: context.theme.destructive),
        );
        return false;
      }
      String? getQuillJsonOrNull(quill.QuillController controller) {
        if (controller.document.isEmpty() || controller.document.toPlainText().trim().isEmpty) {
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
          SnackBar(content: const Text('Nội dung không được để trống'), backgroundColor: context.theme.destructive),
        );
        return false;
      }

      final blogVm = context.read<BlogVm>();
      bool success;
      final messenger = ScaffoldMessenger.of(context);

      if (widget.isUpdate) {
        success = await blogVm.updateBlog(
          widget.blogId!,
          title: _titleController.text.trim(),
          content: jsonContent,
          categoryId: _selectedCategory!.id,
          status: _selectedStatus,
        );
      } else {
        success = await blogVm.createBlog(
          title: _titleController.text.trim(),
          content: jsonContent,
          categoryId: _selectedCategory!.id,
        );
      }

      if (mounted) {
        if (success) {
          messenger.showSnackBar(
              SnackBar(
                content: Text('${widget.isUpdate ? 'Cập nhật' : 'Tạo'} bài viết thành công!'),
                backgroundColor: context.theme.green,
                duration: const Duration(seconds: 2),
              )
          );
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) Navigator.of(context).pop(true);
        } else {
          messenger.showSnackBar(
              SnackBar(
                content: Text(blogVm.error ?? '${widget.isUpdate ? 'Cập nhật' : 'Tạo'} bài viết thất bại.'),
                backgroundColor: context.theme.destructive,
              )
          );
          blogVm.clearError();
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
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.2 * index, 1.0, curve: Curves.easeOutCubic),
        )),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final blogVm = context.watch<BlogVm>();

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnimatedFormField(
              index: 0,
              child: TextFormField(
                controller: _titleController,
                style: TextStyle(color: theme.textColor),
                decoration: InputDecoration(
                    labelText: 'Tiêu đề bài viết',
                    labelStyle: TextStyle(color: theme.mutedForeground),
                    prefixIcon: Icon(Icons.title_rounded, color: theme.primary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primary, width: 1.5)),
                    filled: true,
                    fillColor: theme.input,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  if (value.trim().length < 10 || value.trim().length > 500) {
                    return 'Tiêu đề phải từ 10 đến 500 ký tự';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),

            _buildAnimatedFormField(
              index: 1,
              child: blogVm.isLoadingCategories
                  ? Container(
                height: 58,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: theme.input,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border)
                ),
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 20, color: theme.mutedForeground),
                    const SizedBox(width: 12),
                    const Text('Đang tải danh mục...', style: TextStyle(color: Colors.grey))
                  ],
                ),
              )
                  : DropdownButtonFormField<BlogCategory>(
                value: _selectedCategory,
                hint: Text('Chọn danh mục', style: TextStyle(color: theme.mutedForeground)),
                isExpanded: true,
                style: TextStyle(color: theme.textColor, fontSize: 15),
                decoration: InputDecoration(
                    labelText: 'Danh mục',
                    labelStyle: TextStyle(color: theme.mutedForeground),
                    prefixIcon: Icon(Icons.category_outlined, color: theme.primary, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primary, width: 1.5)),
                    filled: true,
                    fillColor: theme.input,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                ),
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.mutedForeground),
                dropdownColor: theme.popover,
                items: blogVm.categories.map((category) {
                  return DropdownMenuItem<BlogCategory>(
                    value: category,
                    child: Text(category.name, style: TextStyle(color: theme.popoverForeground)),
                  );
                }).toList(),
                onChanged: blogVm.categories.isEmpty ? null : (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) => (value == null || value.id.isEmpty) ? 'Vui lòng chọn danh mục' : null,
              ),
            ),
            if (blogVm.categoryError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12),
                child: Text(blogVm.categoryError!, style: TextStyle(color: theme.destructive, fontSize: 12)),
              ),
            const SizedBox(height: 20),

            if (widget.isUpdate) ...[
              _buildAnimatedFormField(
                index: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  style: TextStyle(color: theme.textColor, fontSize: 15),
                  decoration: InputDecoration(
                      labelText: 'Trạng thái',
                      labelStyle: TextStyle(color: theme.mutedForeground),
                      prefixIcon: Icon(Icons.toggle_on_outlined, color: theme.primary, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.primary, width: 1.5)),
                      filled: true,
                      fillColor: theme.input,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                  ),
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.mutedForeground),
                  dropdownColor: theme.popover,
                  items: ['DRAFT', 'PUBLISHED', 'ARCHIVED'].map((status) {
                    String statusText;
                    Color statusColor;
                    switch (status) {
                      case 'PUBLISHED':
                        statusText = 'Xuất bản';
                        statusColor = theme.green;
                        break;
                      case 'ARCHIVED':
                        statusText = 'Lưu trữ';
                        statusColor = theme.mutedForeground;
                        break;
                      case 'DRAFT':
                      default:
                        statusText = 'Bản nháp';
                        statusColor = theme.yellow;
                        break;
                    }
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: statusColor),
                          const SizedBox(width: 8),
                          Text(statusText, style: TextStyle(color: theme.popoverForeground))
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                  validator: (value) => value == null ? 'Vui lòng chọn trạng thái' : null,
                ),
              ),
              const SizedBox(height: 20),
            ],

            _buildAnimatedFormField(
              index: widget.isUpdate ? 3 : 2,
              child: QuillEditor(
                label: "Nội dung bài viết",
                controller: _contentController,
                isReadOnly: false,
              ),
            ),
            const SizedBox(height: 32),

            _buildAnimatedFormField(
              index: widget.isUpdate ? 4 : 3,
              child: Center(
                child: AnimatedSubmitButton(
                  onSubmit: _submitForm,
                  idleText: widget.isUpdate ? 'Lưu thay đổi' : 'Tạo bài viết',
                  loadingText: 'Đang xử lý...',
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