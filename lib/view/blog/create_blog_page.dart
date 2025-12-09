import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/blog_form.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class CreateBlogPage extends StatefulWidget {
  const CreateBlogPage({super.key});

  @override
  State<CreateBlogPage> createState() => _CreateBlogPageState();
}

class _CreateBlogPageState extends State<CreateBlogPage> {
  final GlobalKey<BlogFormState> _formKey = GlobalKey<BlogFormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        elevation: 0.5,
        title: Text(
          AppLocalizations.of(context).translate('create_blog_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: context.theme.white),
            onPressed: () {
              _formKey.currentState?.submitForm();
            },
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: BlogForm(key: _formKey, isUpdate: false, blogId: null),
    );
  }
}
