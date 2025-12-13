import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/blog.dart';
import 'package:pbl6mobile/model/services/remote/blog_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../shared/widgets/common/image_display.dart';

class BlogDetailPage extends StatefulWidget {
  final Blog blog;

  const BlogDetailPage({super.key, required this.blog});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  late Blog _blog;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _blog = widget.blog; // Initial display with passed data
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    try {
      final fullBlog = await BlogService.getBlogDetail(_blog.id);
      if (fullBlog != null && mounted) {
        setState(() {
          _blog = fullBlog;
        });
      }
    } catch (e) {
      debugPrint('Error loading blog details: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _processHtmlContent(String content) {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    if (baseUrl.isEmpty) return content;

    final uri = Uri.parse(baseUrl);
    final String hostUrl = '${uri.scheme}://${uri.authority}';

    // Replace relative paths starting with /
    // src="/uploads/..." -> src="http://host/uploads/..."
    String processed = content.replaceAll('src="/', 'src="$hostUrl/');
    processed = processed.replaceAll("src='/", "src='$hostUrl/");

    // Remove explicit height and width attributes from img tags to allow flutter_html Style to control sizing
    processed = processed.replaceAll(RegExp(r'height="\d+"'), '');
    processed = processed.replaceAll(RegExp(r'width="\d+"'), '');
    processed = processed.replaceAll(RegExp(r"height='\d+'"), '');
    processed = processed.replaceAll(RegExp(r"width='\d+'"), '');

    return processed;
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat(
      'MMMM d, yyyy',
    ).format(_blog.createdAt.toLocal());
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
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.theme.primary,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (_blog.thumbnailUrl != null && _blog.thumbnailUrl!.isNotEmpty)
              Hero(
                tag: 'blog_thumbnail_${_blog.id}',
                child: CommonImage(
                  imageUrl: _blog.thumbnailUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 100, // Small spacer if no image
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
                          _blog.category.name,
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
                    _blog.title,
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
                                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(_blog.authorName ?? 'Admin')}&background=random',
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
                                _blog.authorName ?? 'Super Admin',
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
                    ],
                  ),

                  const Divider(height: 48),

                  // Content
                  if (_isLoading &&
                      (_blog.content == null || _blog.content!.isEmpty))
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: context.theme.primary,
                        ),
                      ),
                    )
                  else
                    Html(
                      data: _processHtmlContent(
                        _blog.content ??
                            '<p>${AppLocalizations.of(context).translate('no_content')}</p>',
                      ),
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(16),
                          lineHeight: LineHeight(1.6),
                          color: isDark
                              ? const Color(0xFFE0E0E0)
                              : const Color(0xFF333333),
                          fontFamily: 'Roboto',
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
