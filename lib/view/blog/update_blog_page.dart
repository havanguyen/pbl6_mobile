import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/blog_form.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class UpdateBlogPage extends StatefulWidget {
  final String blogId;

  const UpdateBlogPage({super.key, required this.blogId});

  @override
  _UpdateBlogPageState createState() => _UpdateBlogPageState();
}

class _UpdateBlogPageState extends State<UpdateBlogPage> {
  final GlobalKey<BlogFormState> _formKey = GlobalKey<BlogFormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BlogVm>().fetchBlogDetail(widget.blogId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        elevation: 0.5,
        title: Text(
          AppLocalizations.of(context).translate('update_blog_title'),
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
      body: Consumer<BlogVm>(
        builder: (context, blogVm, child) {
          if (blogVm.isLoadingDetail) {
            return const Center(child: CircularProgressIndicator());
          }
          if (blogVm.blogDetail == null && blogVm.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "${AppLocalizations.of(context).translate('error_occurred')}${blogVm.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.theme.destructive),
                ),
              ),
            );
          }
          if (blogVm.blogDetail == null) {
            return Center(
              child: Text(
                AppLocalizations.of(context).translate('no_blogs_found'),
              ),
            );
          }
          return BlogForm(
            key: _formKey,
            isUpdate: true,
            blogId: widget.blogId,
            initialData: blogVm.blogDetail,
          );
        },
      ),
    );
  }
}
