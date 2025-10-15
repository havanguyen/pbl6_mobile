import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pbl6mobile/model/entities/info_section.dart';
import 'package:pbl6mobile/shared/widgets/widget/info_section_delete_confirm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

class SpecialtyDetailPage extends StatefulWidget {
  final Map<String, dynamic> specialty;

  const SpecialtyDetailPage({super.key, required this.specialty});

  @override
  State<SpecialtyDetailPage> createState() => _SpecialtyDetailPageState();
}

class _SpecialtyDetailPageState extends State<SpecialtyDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<SpecialtyVm>()
          .fetchInfoSections(widget.specialty['id'], forceRefresh: true);
    });
  }

  void _showDeleteDialog(InfoSection infoSection) {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteInfoSectionConfirmationDialog(
        infoSection: infoSection,
        specialtyId: widget.specialty['id'],
        onDeleteSuccess: () {
          context
              .read<SpecialtyVm>()
              .fetchInfoSections(widget.specialty['id'], forceRefresh: true);
        },
        snackbarService: snackbarService,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: context.theme.mutedForeground,
          ),
          const SizedBox(height: 20),
          Text(
            'Chưa có phần thông tin nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Nhấn nút + ở góc dưới để thêm thông tin chi tiết cho chuyên khoa này.',
              style: TextStyle(color: context.theme.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final provider = context.watch<SpecialtyVm>();
    final isOffline = provider.isOffline;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.specialty['name']),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.isInfoSectionLoading
                ? null
                : () => provider.fetchInfoSections(widget.specialty['id'],
                forceRefresh: true),
          )
        ],
      ),
      backgroundColor: theme.bg,
      body: Column(
        children: [
          if (isOffline)
            Container(
              width: double.infinity,
              color: context.theme.yellow,
              padding: const EdgeInsets.all(8.0),
              child:  Text(
                'Bạn đang ở chế độ offline. Dữ liệu có thể đã cũ.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.theme.popover),
              ),
            ),
          Expanded(
            child: Consumer<SpecialtyVm>(
              builder: (context, provider, child) {
                if (provider.isInfoSectionLoading &&
                    provider.getInfoSectionsFor(widget.specialty['id']).isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final infoSections =
                provider.getInfoSectionsFor(widget.specialty['id']);
                if (infoSections.isEmpty) {
                  return _buildEmptyState();
                }
                return AnimationLimiter(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: infoSections.length,
                    itemBuilder: (context, index) {
                      final info = infoSections[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _InfoSectionTile(
                              info: info,
                              isOffline: isOffline,
                              onDelete: () => _showDeleteDialog(info),
                              onEdit: () async {
                                final result = await Navigator.pushNamed(
                                  context,
                                  Routes.updateInfoSection,
                                  arguments: {
                                    'infoSection': info.toJson(),
                                    'specialtyId': widget.specialty['id']
                                  },
                                );
                                if (result == true && mounted) {
                                  provider.fetchInfoSections(
                                      widget.specialty['id'],
                                      forceRefresh: true);
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isOffline ? null : FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            Routes.createInfoSection,
            arguments: widget.specialty['id'],
          );
          if (result == true && mounted) {
            context
                .read<SpecialtyVm>()
                .fetchInfoSections(widget.specialty['id'], forceRefresh: true);
          }
        },
        backgroundColor: theme.primary,
        child:  Icon(Icons.add, color: context.theme.white),
      ),
    );
  }
}

class _InfoSectionTile extends StatefulWidget {
  final InfoSection info;
  final bool isOffline;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InfoSectionTile({
    required this.info,
    required this.isOffline,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  _InfoSectionTileState createState() => _InfoSectionTileState();
}

class _InfoSectionTileState extends State<_InfoSectionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.theme.popover.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color:
                          _isExpanded ? theme.border : Colors.transparent))),
              child: Row(
                children: [
                  Icon(Icons.article_outlined, color: theme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.info.name.toUpperCase(),
                      style: TextStyle(
                        color: theme.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: theme.primary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Container(
              height: _isExpanded ? null : 0,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ExpandableHtmlContent(
                    content: widget.info.content,
                    theme: theme,
                  ),
                  if (!widget.isOffline) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: widget.onEdit,
                          icon: Icon(Icons.edit_outlined,
                              size: 18, color: theme.primary),
                          label: Text('Sửa',
                              style: TextStyle(color: theme.primary)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: widget.onDelete,
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: theme.destructive),
                          label: Text('Xóa',
                              style: TextStyle(color: theme.destructive)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableHtmlContent extends StatefulWidget {
  final String content;
  final CustomThemeExtension theme;

  const _ExpandableHtmlContent({
    required this.content,
    required this.theme,
  });

  @override
  __ExpandableHtmlContentState createState() => __ExpandableHtmlContentState();
}

class __ExpandableHtmlContentState extends State<_ExpandableHtmlContent> {
  bool _isShowingFull = false;
  late final String htmlContent;
  late final bool isLongContent;

  @override
  void initState() {
    super.initState();
    try {
      final deltaJson = jsonDecode(widget.content);
      final converter = QuillDeltaToHtmlConverter(List.castFrom(deltaJson));
      htmlContent = converter.convert();
    } catch (e) {
      htmlContent = widget.content.replaceAll('\n', '<br>');
    }
    isLongContent = htmlContent.length > 400;
  }

  @override
  Widget build(BuildContext context) {
    final styles = {
      "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
      "p": Style(
          fontSize: FontSize(15),
          color: widget.theme.mutedForeground,
          lineHeight: LineHeight.em(1.5)),
      "h1, h2, h3":
      Style(fontWeight: FontWeight.w600, color: widget.theme.textColor),
      "li": Style(
          fontSize: FontSize(15),
          color: widget.theme.mutedForeground,
          lineHeight: LineHeight.em(1.5)),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: isLongContent && !_isShowingFull
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [context.theme.popover, context.theme.popover, Colors.transparent],
                stops: [0.0, 0.7, 1.0],
              ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
            },
            blendMode: BlendMode.dstIn,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: Html(data: htmlContent, style: styles),
            ),
          ),
          secondChild: Html(data: htmlContent, style: styles),
        ),
        if (isLongContent)
          GestureDetector(
            onTap: () => setState(() => _isShowingFull = !_isShowingFull),
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _isShowingFull ? '... Thu gọn' : 'Xem thêm ...',
                style: TextStyle(
                  color: widget.theme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}