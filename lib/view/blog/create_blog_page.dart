import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/blog_form.dart';

class CreateBlogPage extends StatelessWidget {
  const CreateBlogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.card, // Consistent Appbar
        elevation: 0.5,
        title: Text(
          'Tạo bài viết mới',
          style: TextStyle(
            color: context.theme.textColor,
            fontWeight: FontWeight.w600, // Bold title
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.textColor),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      backgroundColor: context.theme.bg,
      body: const BlogForm(
        isUpdate: false,
        blogId: null,
      ),
    );
  }
}