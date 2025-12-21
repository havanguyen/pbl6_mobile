import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/stats/stats.types.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:pbl6mobile/model/entities/review/review_analysis.dart';
import 'package:pbl6mobile/view_model/reviews/review_analysis_vm.dart';
import 'package:pbl6mobile/view_model/stats/stats_vm.dart';

class DoctorStatsPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorStatsPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  State<DoctorStatsPage> createState() => _DoctorStatsPageState();
}

class _DoctorStatsPageState extends State<DoctorStatsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsVm>().fetchDoctorStatsById(widget.doctorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReviewAnalysisVm()..fetchAnalyses(widget.doctorId),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: context.theme.bg,
          appBar: AppBar(
            title: Text(
              '${AppLocalizations.of(context).translate('statistics')} - ${widget.doctorName}',
              style: TextStyle(color: context.theme.white),
            ),
            backgroundColor: context.theme.appBar,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.theme.white),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              indicatorColor: context.theme.primary,
              labelColor: context.theme.white,
              unselectedLabelColor: context.theme.white.withOpacity(0.7),
              tabs: [
                Tab(text: AppLocalizations.of(context).translate('overview')),
                Tab(text: AppLocalizations.of(context).translate('ai_analyze')),
              ],
            ),
          ),
          body: Consumer<StatsVm>(
            builder: (context, vm, child) {
              if (vm.isLoadingDoctorStats) {
                return const Center(child: CircularProgressIndicator());
              }

              if (vm.selectedDoctorStats == null) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context).translate('no_data'),
                    style: TextStyle(color: context.theme.textColor),
                  ),
                );
              }

              final stats = vm.selectedDoctorStats!;
              return TabBarView(
                children: [
                  _buildOverviewTab(context, stats),
                  _buildAiAnalyzeTab(context),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, DoctorMyStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBookingSection(context, stats.booking),
          const SizedBox(height: 24),
          _buildContentSection(context, stats.content),
          const SizedBox(height: 24),
          _buildPerformanceOverview(context, stats),
        ],
      ),
    );
  }

  Widget _buildAiAnalyzeTab(BuildContext context) {
    return Consumer<ReviewAnalysisVm>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.analyses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('analysis_history'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateAnalysisDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      AppLocalizations.of(context).translate('new_analysis'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primary,
                      foregroundColor: context.theme.white,
                    ),
                  ),
                ],
              ),
            ),
            if (vm.analyses.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: context.theme.mutedForeground,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).translate('no_analysis'),
                        style: TextStyle(
                          color: context.theme.textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(
                          context,
                        ).translate('create_first_analysis'),
                        style: TextStyle(color: context.theme.mutedForeground),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: vm.analyses.length,
                  itemBuilder: (context, index) {
                    final analysis = vm.analyses[index];
                    return Card(
                      color: context.theme.card,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.theme.border),
                      ),
                      child: InkWell(
                        onTap: () => _showAnalysisDetail(context, analysis),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.theme.primary.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      analysis.dateRange == DateRangeType.mtd
                                          ? 'MTD'
                                          : 'YTD',
                                      style: TextStyle(
                                        color: context.theme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDate(analysis.createdAt),
                                    style: TextStyle(
                                      color: context.theme.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Html(
                                data: analysis.summary,
                                style: {
                                  "body": Style(
                                    margin: Margins.zero,
                                    padding: HtmlPaddings.zero,
                                    maxLines: 3,
                                    textOverflow: TextOverflow.ellipsis,
                                    color: context.theme.textColor,
                                    fontSize: FontSize(14),
                                  ),
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: context.theme.mutedForeground,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    analysis.creatorName,
                                    style: TextStyle(
                                      color: context.theme.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  void _showCreateAnalysisDialog(BuildContext context) {
    final vm = context.read<ReviewAnalysisVm>();
    showDialog(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: vm,
        child: CreateAnalysisDialog(
          doctorId: widget.doctorId,
          onCreated: () {
            // VM notifies listeners, list updates automatically
          },
        ),
      ),
    );
  }

  void _showAnalysisDetail(
    BuildContext context,
    ReviewAnalysisListItem listItem,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => ChangeNotifierProvider.value(
          value: context.read<ReviewAnalysisVm>(),
          child: AnalysisDetailSheet(
            analysisId: listItem.id,
            scrollController: controller,
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildBookingSection(
    BuildContext context,
    DoctorBookingStats booking,
  ) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('booking_stats'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                localizations.translate('total_appointments'),
                booking.total.toString(),
                Icons.calendar_today,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                localizations.translate('confirmed'),
                booking.confirmedCount.toString(),
                Icons.access_time,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                'Completed',
                booking.completedCount.toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
              _buildStatCard(
                context,
                localizations.translate('completed_rate'),
                '${booking.completedRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(
    BuildContext context,
    DoctorContentStats content,
  ) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('content_stats'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                context,
                localizations.translate('avg_rating'),
                '${content.averageRating.toStringAsFixed(1)} ★ (${content.totalReviews})',
                Icons.star,
                Colors.amber,
              ),
              _buildStatCard(
                context,
                localizations.translate('published_blogs'),
                content.totalBlogs.toString(),
                Icons.article,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                localizations.translate('qa_answers'),
                content.totalAnswers.toString(),
                Icons.question_answer,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                localizations.translate('accepted_answers'),
                '${content.totalAcceptedAnswers} (${content.answerAcceptedRate}%)',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview(BuildContext context, DoctorMyStats stats) {
    if (stats.content.averageRating == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('performance_overview'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPerfItem(
                  context,
                  stats.content.averageRating.toStringAsFixed(1),
                  AppLocalizations.of(context).translate('avg_rating'),
                  Colors.amber,
                ),
              ),
              Expanded(
                child: _buildPerfItem(
                  context,
                  stats.content.totalReviews.toString(),
                  AppLocalizations.of(context).translate('total_reviews'),
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildPerfItem(
                  context,
                  stats.booking.completedCount.toString(),
                  'Completed',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerfItem(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.theme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.theme.input),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: context.theme.textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.theme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class CreateAnalysisDialog extends StatefulWidget {
  final String doctorId;
  final VoidCallback onCreated;

  const CreateAnalysisDialog({
    super.key,
    required this.doctorId,
    required this.onCreated,
  });

  @override
  State<CreateAnalysisDialog> createState() => _CreateAnalysisDialogState();
}

class _CreateAnalysisDialogState extends State<CreateAnalysisDialog> {
  DateRangeType _selectedRange = DateRangeType.mtd;
  bool _includeNonPublic = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewAnalysisVm>();
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: context.theme.card,
      title: Text(
        localizations.translate('create_analysis'),
        style: TextStyle(color: context.theme.textColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('select_date_range'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.theme.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<DateRangeType>(
            value: _selectedRange,
            items: [
              DropdownMenuItem(
                value: DateRangeType.mtd,
                child: Text(localizations.translate('mtd')),
              ),
              DropdownMenuItem(
                value: DateRangeType.ytd,
                child: Text(localizations.translate('ytd')),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _selectedRange = value);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: context.theme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.theme.border),
              ),
            ),
            dropdownColor: context.theme.card,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _includeNonPublic,
            onChanged: (value) => setState(() => _includeNonPublic = value!),
            title: Text(
              localizations.translate('include_non_public'),
              style: TextStyle(fontSize: 14, color: context.theme.textColor),
            ),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: context.theme.primary,
          ),
          if (vm.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                vm.error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            localizations.translate('cancel'),
            style: TextStyle(color: context.theme.mutedForeground),
          ),
        ),
        ElevatedButton(
          onPressed: vm.isCreating
              ? null
              : () async {
                  final request = CreateReviewAnalysisRequest(
                    doctorId: widget.doctorId,
                    dateRange: _selectedRange,
                    includeNonPublic: _includeNonPublic,
                  );
                  final success = await vm.createAnalysis(request);
                  if (success && mounted) {
                    widget.onCreated();
                    Navigator.pop(context);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: context.theme.primary,
            foregroundColor: context.theme.white,
          ),
          child: vm.isCreating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(localizations.translate('create')),
        ),
      ],
    );
  }
}

class AnalysisDetailSheet extends StatefulWidget {
  final String analysisId;
  final ScrollController scrollController;

  const AnalysisDetailSheet({
    super.key,
    required this.analysisId,
    required this.scrollController,
  });

  @override
  State<AnalysisDetailSheet> createState() => _AnalysisDetailSheetState();
}

class _AnalysisDetailSheetState extends State<AnalysisDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewAnalysisVm>().fetchAnalysisDetail(widget.analysisId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReviewAnalysisVm>();
    final analysis = vm.currentAnalysis;
    final localizations = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.theme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: vm.isLoading || analysis == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.theme.mutedForeground.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: ListView(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Header
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations.translate('analysis_detail'),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: context.theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${analysis.dateRange == DateRangeType.mtd ? localizations.translate("month_to_date") : localizations.translate("year_to_date")} • ${_formatDate(analysis.createdAt)}',
                                  style: TextStyle(
                                    color: context.theme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.theme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              analysis.dateRange == DateRangeType.mtd
                                  ? localizations.translate('mtd').toUpperCase()
                                  : localizations
                                        .translate('ytd')
                                        .toUpperCase(),
                              style: TextStyle(
                                color: context.theme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Stats Overview
                      _buildStatsGrid(context, analysis),
                      const SizedBox(height: 24),
                      Divider(color: context.theme.border),
                      const SizedBox(height: 16),
                      // Summary
                      _buildSectionTitle(
                        context,
                        localizations.translate('summary'),
                        Icons.summarize,
                        Colors.blue,
                      ),
                      Html(data: analysis.summary),
                      // Key Strengths
                      _buildSectionTitle(
                        context,
                        localizations.translate('key_strengths'),
                        Icons.thumb_up,
                        Colors.green,
                      ),
                      Html(data: analysis.advantages),
                      // Areas for Improvement
                      _buildSectionTitle(
                        context,
                        localizations.translate('areas_for_improvement'),
                        Icons.thumb_down,
                        Colors
                            .orange, // React uses Amber for Improvement? No, Amber for Recommendations. React uses Amber-600 for Areas.
                      ),
                      Html(data: analysis.disadvantages),
                      // Notable Changes
                      _buildSectionTitle(
                        context,
                        localizations.translate('notable_changes'),
                        Icons.info_outline, // Blue
                        Colors.blue,
                      ),
                      Html(data: analysis.changes),
                      // Recommendations
                      _buildSectionTitle(
                        context,
                        localizations.translate('recommendations'),
                        Icons.lightbulb,
                        Colors.purple, // React uses Purple
                      ),
                      Html(data: analysis.recommendations),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, ReviewAnalysis analysis) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                context,
                AppLocalizations.of(context).translate('avg_rating'),
                analysis.period1Avg.toStringAsFixed(1),
                analysis.period2Avg.toStringAsFixed(1),
                analysis.avgChange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailCard(
                context,
                AppLocalizations.of(context).translate('reviews_change'),
                analysis.period1Total.toString(),
                analysis.period2Total.toString(),
                analysis.totalChange.toDouble(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildChangeSummaryCard(context, analysis),
      ],
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String current,
    String previous,
    double change,
  ) {
    final isPositive = change > 0;
    final isNegative = change < 0;
    final changeColor = isPositive
        ? Colors.green
        : (isNegative ? Colors.red : context.theme.mutedForeground);
    final changeIcon = isPositive
        ? Icons.arrow_upward
        : (isNegative ? Icons.arrow_downward : Icons.remove);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.theme.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                  Text(
                    '${AppLocalizations.of(context).translate('was')} $previous',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.mutedForeground,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(changeIcon, size: 16, color: changeColor),
                  Text(
                    '${isPositive ? "+" : ""}${change.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeSummaryCard(
    BuildContext context,
    ReviewAnalysis analysis,
  ) {
    final changePercent = analysis.period2Avg > 0
        ? ((analysis.avgChange / analysis.period2Avg) * 100).toStringAsFixed(1)
        : '0.0';
    final totalPercent = analysis.period2Total > 0
        ? ((analysis.totalChange / analysis.period2Total) * 100)
              .toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('change_label'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.theme.mutedForeground,
            ),
          ),
          const SizedBox(height: 8),
          _buildChangeRow(
            context,
            AppLocalizations.of(context).translate('reviews_change'),
            analysis.totalChange.toDouble(),
            totalPercent,
          ),
          const SizedBox(height: 8),
          _buildChangeRow(
            context,
            AppLocalizations.of(context).translate('rating_change'),
            analysis.avgChange,
            changePercent,
          ),
        ],
      ),
    );
  }

  Widget _buildChangeRow(
    BuildContext context,
    String label,
    double change,
    String percent,
  ) {
    final isPositive = change > 0;
    final isNegative = change < 0;
    final color = isPositive
        ? Colors.green
        : (isNegative ? Colors.red : context.theme.mutedForeground);
    final icon = isPositive
        ? Icons.arrow_upward
        : (isNegative ? Icons.arrow_downward : Icons.remove);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.theme.mutedForeground),
        ),
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
