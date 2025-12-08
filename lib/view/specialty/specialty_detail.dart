import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pbl6mobile/model/entities/info_section.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/shared/widgets/widget/info_section_delete_confirm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class SpecialtyDetailPage extends StatefulWidget {
  final Specialty specialty;

  const SpecialtyDetailPage({super.key, required this.specialty});

  @override
  State<SpecialtyDetailPage> createState() => _SpecialtyDetailPageState();
}

class _SpecialtyDetailPageState extends State<SpecialtyDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpecialtyVm>().fetchInfoSections(
        widget.specialty.id,
        forceRefresh: true,
      );
    });
  }

  void _showDeleteDialog(InfoSection infoSection) {
    final snackbarService = Provider.of<SnackbarService>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteInfoSectionConfirmationDialog(
        infoSection: infoSection,
        specialtyId: widget.specialty.id,
        onDeleteSuccess: () {
          context.read<SpecialtyVm>().fetchInfoSections(
            widget.specialty.id,
            forceRefresh: true,
          );
        },
        snackbarService: snackbarService,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
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
              AppLocalizations.of(context).translate('no_info_sections_yet'),
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
                AppLocalizations.of(
                  context,
                ).translate('add_new_info_section_hint'),
                style: TextStyle(color: context.theme.mutedForeground),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final provider = context.watch<SpecialtyVm>();
    final isOffline = provider.isOffline;

    return Scaffold(
      backgroundColor: theme.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.primary,
            iconTheme: IconThemeData(color: theme.white),
            title: Text(
              AppLocalizations.of(context).translate('specialty'),
              style: TextStyle(
                color: theme.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: theme.white),
                onPressed: provider.isInfoSectionLoading
                    ? null
                    : () => provider.fetchInfoSections(
                        widget.specialty.id,
                        forceRefresh: true,
                      ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: theme.card,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.specialty.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
                      height: 1.2,
                    ),
                  ),
                  if (widget.specialty.description != null &&
                      widget.specialty.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.specialty.description!,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: theme.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isOffline)
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                color: theme.yellow,
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  AppLocalizations.of(context).translate('offline_banner'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.popover),
                ),
              ),
            ),
          Consumer<SpecialtyVm>(
            builder: (context, provider, child) {
              if (provider.isInfoSectionLoading &&
                  provider.getInfoSectionsFor(widget.specialty.id).isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final infoSections = provider.getInfoSectionsFor(
                widget.specialty.id,
              );
              if (infoSections.isEmpty) {
                return _buildEmptyState();
              }
              return AnimationLimiter(
                child: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final info = infoSections[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8, // Added padding between items
                            ),
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
                                    'specialtyId': widget.specialty.id,
                                  },
                                );
                                if (result == true && mounted) {
                                  provider.fetchInfoSections(
                                    widget.specialty.id,
                                    forceRefresh: true,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: infoSections.length),
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: isOffline
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  Routes.createInfoSection,
                  arguments: widget.specialty.id,
                );
                if (result == true && mounted) {
                  context.read<SpecialtyVm>().fetchInfoSections(
                    widget.specialty.id,
                    forceRefresh: true,
                  );
                }
              },
              backgroundColor: theme.primary,
              child: Icon(Icons.add, color: theme.white),
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
          ),
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
                color: _isExpanded
                    ? theme.primary.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.article_rounded,
                      color: theme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
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
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.mutedForeground,
                    ),
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
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: theme.primary,
                          ),
                          label: Text(
                            AppLocalizations.of(context).translate('edit'),
                            style: TextStyle(color: theme.primary),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: widget.onDelete,
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: theme.destructive,
                          ),
                          label: Text(
                            AppLocalizations.of(context).translate('delete'),
                            style: TextStyle(color: theme.destructive),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  const _ExpandableHtmlContent({required this.content, required this.theme});

  @override
  __ExpandableHtmlContentState createState() => __ExpandableHtmlContentState();
}

class __ExpandableHtmlContentState extends State<_ExpandableHtmlContent> {
  bool _isShowingFull = false;
  String? htmlContent;
  bool isLongContent = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHtml();
  }

  @override
  void didUpdateWidget(_ExpandableHtmlContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content) {
      _loadHtml();
    }
  }

  Future<void> _loadHtml() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Offload JSON parsing to a separate isolate to prevent UI jank
    final parsedHtml = await compute(_parseHtmlString, widget.content);

    if (mounted) {
      setState(() {
        htmlContent = parsedHtml;
        isLongContent = parsedHtml.length > 400;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SizedBox(
          height: 100,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.theme.primary.withOpacity(0.5),
              ),
            ),
          ),
        ),
      );
    }

    final styles = {
      "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
      "p": Style(
        fontSize: FontSize(15),
        color: widget.theme.mutedForeground,
        lineHeight: LineHeight.em(1.5),
      ),
      "h1, h2, h3": Style(
        fontWeight: FontWeight.w600,
        color: widget.theme.textColor,
      ),
      "li": Style(
        fontSize: FontSize(15),
        color: widget.theme.mutedForeground,
        lineHeight: LineHeight.em(1.5),
      ),
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
                colors: [
                  context.theme.popover,
                  context.theme.popover,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.7, 1.0],
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
                _isShowingFull
                    ? AppLocalizations.of(context).translate('view_less')
                    : AppLocalizations.of(context).translate('view_more'),
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

String _parseHtmlString(String content) {
  try {
    final deltaJson = jsonDecode(content);
    if (deltaJson is List) {
      final converter = QuillDeltaToHtmlConverter(List.castFrom(deltaJson));
      return converter.convert();
    }
    return content.replaceAll('\n', '<br>');
  } catch (e) {
    return content.replaceAll('\n', '<br>');
  }
}
