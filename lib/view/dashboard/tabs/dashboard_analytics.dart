import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/stats/stats.types.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/stats/stats_vm.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/animations/fade_in_up.dart';
import '../../../../shared/localization/app_localizations.dart';

class DashboardAnalytics extends StatelessWidget {
  const DashboardAnalytics({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsVm>(
      builder: (context, vm, child) {
        if (vm.isLoadingRevenue || vm.isLoadingTopDoctors) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(
                context,
                AppLocalizations.of(context).translate('revenue_trend'),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: _buildRevenueLineChart(context, vm.revenueStats),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(
                context,
                AppLocalizations.of(context).translate('efficiency_metrics'),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildEfficiencyStats(context, vm),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _buildReviewQAStats(context, vm),
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(
                context,
                AppLocalizations.of(context).translate('revenue_by_doctor'),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: _buildDoctorPieChart(context, vm.revenueByDoctorStats),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    // TODO: Add keys to localization if sticking to English for now or add keys later
    // For now I'll use hardcoded or try to repurpose existing keys if close enough
    // "Revenue Trend" -> "Doanh thu theo thời gian"
    // "Revenue by Doctor" -> "Doanh thu theo bác sĩ"
    return Text(
      title, // Placeholder, usually would use translate
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: context.theme.textColor,
      ),
    );
  }

  Widget _buildRevenueLineChart(BuildContext context, List<RevenueStats> data) {
    if (data.isEmpty) return const SizedBox();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
      ),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => context.theme.popover,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${data[spot.x.toInt()].name}\n${spot.y.toStringAsFixed(0)}',
                    TextStyle(color: context.theme.textColor),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: context.theme.border,
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final idx = value.toInt();
                  // Show every 2nd label to avoid crowding line chart
                  if (idx % 2 != 0) return const SizedBox.shrink();

                  final name = data[idx].name.split(' ').first;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 10,
                        color: context.theme.mutedForeground,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    _formatYAxis(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: context.theme.mutedForeground,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) {
                return FlSpot(
                  e.key.toDouble(),
                  (e.value.total['VND'] ?? 0).toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: context.theme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.theme.primary.withOpacity(0.3),
                    context.theme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorPieChart(
    BuildContext context,
    List<RevenueByDoctorStats> data,
  ) {
    if (data.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.asMap().entries.map((e) {
                  final index = e.key;
                  final item = e.value;
                  final value = (item.total['VND'] ?? 0).toDouble();

                  // Generate colors
                  final color = HSLColor.fromColor(context.theme.primary)
                      .withLightness((0.4 + (index * 0.1)).clamp(0.2, 0.8))
                      .toColor();

                  return PieChartSectionData(
                    color: color,
                    value: value,
                    title: '${(value / 1000000).toStringAsFixed(1)}M',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: data.asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;
              final color = HSLColor.fromColor(
                context.theme.primary,
              ).withLightness((0.4 + (index * 0.1)).clamp(0.2, 0.8)).toColor();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.doctor.fullName,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.mutedForeground,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyStats(BuildContext context, StatsVm vm) {
    if (vm.isLoadingAppointments ||
        vm.isLoadingPatients ||
        vm.isLoadingRevenue) {
      return const Center(child: CircularProgressIndicator());
    }

    final revPerPatient = vm.avgRevenuePerPatient;
    final revPerAppt = vm.avgRevenuePerAppointment;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              AppLocalizations.of(context).translate('avg_rev_per_patient'),
              '${(revPerPatient / 1000).toStringAsFixed(1)}K',
              Icons.person,
              Colors.indigo,
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context).translate('avg_rev_per_appt'),
              '${(revPerAppt / 1000).toStringAsFixed(1)}K',
              Icons.calendar_month,
              Colors.deepOrange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildReviewQAStats(BuildContext context, StatsVm vm) {
    if (vm.isLoadingReviews || vm.isLoadingQA) {
      return const Center(child: CircularProgressIndicator());
    }

    // Safety check
    final reviewStats = vm.reviewsStats;
    final qaStats = vm.qaStats;

    // Calculate avg rating
    double avgRating = 0;
    if (reviewStats != null && reviewStats.totalReviews > 0) {
      double totalScore = 0;
      reviewStats.ratingCounts.forEach((key, count) {
        final rating = double.tryParse(key) ?? 0;
        totalScore += rating * count;
      });
      avgRating = totalScore / reviewStats.totalReviews;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return GridView.count(
          crossAxisCount: isWide ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              context,
              AppLocalizations.of(context).translate('total_reviews'),
              (reviewStats?.totalReviews ?? 0).toString(),
              Icons.rate_review,
              Colors.cyan,
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context).translate('avg_rating'),
              avgRating.toStringAsFixed(1),
              Icons.star_half,
              Colors.amber,
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context).translate('total_questions'),
              (qaStats?.totalQuestions ?? 0).toString(),
              Icons.help_outline,
              Colors.purple,
            ),
            _buildStatCard(
              context,
              AppLocalizations.of(context).translate('answer_rate'),
              '${(qaStats?.answerRate ?? 0).toStringAsFixed(1)}%',
              Icons.check_circle_outline,
              Colors.teal,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.theme.mutedForeground,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatYAxis(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }
}
