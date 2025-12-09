import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/common/image_display.dart';

class BlogDetailPage extends StatelessWidget {
  final Blog blog;

  const BlogDetailPage({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat(
      'MMMM d, yyyy',
    ).format(blog.createdAt.toLocal());
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.card,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).translate('view_blog_details'),
          style: TextStyle(
            color: context.theme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Potential future actions (Share, etc.)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (blog.thumbnailUrl != null && blog.thumbnailUrl!.isNotEmpty)
              Hero(
                tag: 'blog_thumbnail_${blog.id}',
                child: CommonImage(
                  imageUrl: blog.thumbnailUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height:
                    100, // Small spacer if no image, or maybe a default gradient?
              ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info (Category • Date)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.theme.muted,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          blog.category.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.theme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  $formattedDate',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.theme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    blog.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: context.theme.textColor,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Author & Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: context.theme.primary.withOpacity(
                              0.1,
                            ),
                            child: CommonImage(
                              imageUrl:
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(blog.authorName ?? 'Admin')}&background=random',
                              width: 40,
                              height: 40,
                              borderRadius: 20,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                blog.authorName ?? 'Super Admin',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.theme.textColor,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('author_label'),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.theme.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // View Count
                      /* // Could allow enabling this
                      Row(
                         children: [
                            Icon(Icons.remove_red_eye_rounded, size: 16, color: context.theme.mutedForeground),
                            const SizedBox(width: 4),
                            Text(
                              '${blog.publicIds?.length ?? 0} ${AppLocalizations.of(context).translate('views_label')}', // Note: publicIds isn't exactly view count but close enough based on React code 'viewCount'
                               style: TextStyle(fontSize: 13, color: context.theme.mutedForeground),
                            )
                         ],
                      )
                      */
                    ],
                  ),

                  const Divider(height: 48),

                  // Content
                  Html(
                    data: blog.content ?? '',
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(16),
                        lineHeight: LineHeight(1.6),
                        color: isDark
                            ? const Color(0xFFE0E0E0)
                            : const Color(0xFF333333),
                        fontFamily: 'Roboto', // Or app default font
                      ),
                      "p": Style(margin: Margins.only(bottom: 16)),
                      "h1": Style(
                        fontSize: FontSize(22),
                        fontWeight: FontWeight.bold,
                      ),
                      "h2": Style(
                        fontSize: FontSize(20),
                        fontWeight: FontWeight.bold,
                      ),
                      "h3": Style(
                        fontSize: FontSize(18),
                        fontWeight: FontWeight.bold,
                      ),
                      "blockquote": Style(
                        padding: HtmlPaddings.only(left: 16),
                        border: Border(
                          left: BorderSide(
                            color: context.theme.primary,
                            width: 4,
                          ),
                        ),
                        fontStyle: FontStyle.italic,
                        color: context.theme.mutedForeground,
                      ),
                      "img": Style(
                        width: Width(100, Unit.percent),
                        height: Height.auto(),
                        display: Display.block,
                        margin: Margins.symmetric(vertical: 10),
                      ),
                    },
                    onLinkTap: (url, _, __) {
                      // Handle outside links if needed
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
