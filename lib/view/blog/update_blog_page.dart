import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/widgets/widget/blog_form.dart';
import 'package:pbl6mobile/view_model/blog/blog_vm.dart';
import 'package:provider/provider.dart';

class UpdateBlogPage extends StatefulWidget {
  final String blogId;

  const UpdateBlogPage({super.key, required this.blogId});

  @override
  _UpdateBlogPageState createState() => _UpdateBlogPageState();
}

class _UpdateBlogPageState extends State<UpdateBlogPage> {

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
          backgroundColor: context.theme.card,
          elevation: 0.5,
          title: Text(
            'Chỉnh sửa bài viết',
            style: TextStyle(
              color: context.theme.textColor,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.theme.textColor),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        backgroundColor: context.theme.bg,
        body: Consumer<BlogVm>(
            builder: (context, blogVm, child) {
              if (blogVm.isLoadingDetail) {
                return const Center(child: CircularProgressIndicator());
              }
              if (blogVm.blogDetail == null && blogVm.error != null) {
                return Center(child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Lỗi tải chi tiết: ${blogVm.error}", textAlign: TextAlign.center, style: TextStyle(color: context.theme.destructive)),
                ));
              }
              if (blogVm.blogDetail == null) {
                return const Center(child: Text("Không tìm thấy thông tin bài viết."));
              }
              return BlogForm(
                isUpdate: true,
                blogId: widget.blogId,
                initialData: blogVm.blogDetail,
              );
            }
        )
    );
  }
}