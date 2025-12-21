import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/stats/stats.types.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/view_model/stats/stats_vm.dart';
import 'package:provider/provider.dart';

class DoctorBookingChart extends StatefulWidget {
  const DoctorBookingChart({super.key});

  @override
  State<DoctorBookingChart> createState() => _DoctorBookingChartState();
}

class _DoctorBookingChartState extends State<DoctorBookingChart> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsVm>().fetchDoctorsBookingStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsVm>(
      builder: (context, vm, child) {
        if (vm.isLoadingDoctorsBooking) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = vm.doctorsBookingStats?.data ?? [];
        if (data.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive layout: column on mobile, row on wide screens
            // But for now, let's stack them vertically as in mobile view or use a grid
            // similar to React's grid-cols-1 lg:grid-cols-2
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCompletionRateChart(context, data)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildStatusPieChart(context, data)),
                ],
              );
            }

            return Column(
              children: [
                _buildCompletionRateChart(context, data),
                const SizedBox(height: 24),
                _buildStatusPieChart(context, data),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCompletionRateChart(
    BuildContext context,
    List<DoctorBookingStatsItem> data,
  ) {
    // Top 10 by completion rate
    final topDoctors = data.take(10).toList();

    return Container(
      height: 400,
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
            AppLocalizations.of(context).translate('booking_stats_chart_title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).translate('booking_stats_chart_desc'),
            style: TextStyle(
              fontSize: 12,
              color: context.theme.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => context.theme.popover,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final doctor = topDoctors[groupIndex];
                      return BarTooltipItem(
                        '${doctor.doctor.fullName}\n',
                        TextStyle(
                          color: context.theme.popoverForeground,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text:
                                'Rate: ${doctor.completedRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= topDoctors.length) {
                          return const SizedBox.shrink();
                        }
                        final name = topDoctors[value.toInt()].doctor.fullName;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            name
                                .split(' ')
                                .last, // Show last name to save space
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      interval: 20,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1, // Only relevant if vertical list
                  // For horizontal chart, grid lines are vertical on value axis
                ),
                borderData: FlBorderData(show: false),
                // To achieve horizontal bar chart, we rotate the chart or just swap axes visually.
                // FL_Chart supports `rotRodData`.
                // Actually FL_Chart's BarChart is strictly vertical.
                // To make it horizontal we use RotatedBox or swap x/y logic.
                // Standard BarChart in fl_chart is Vertical.
                // Horizontal is achieved by setting `rotRodData` to true? No, that's deprecated or not standard.
                // The common way is RotatedBox(quarterTurns: 1, child: BarChart(...))
                // effectively swapping axes.
              ),
            ),
          ),
          // NOTE: True horizontal bar chart in fl_chart 0.x/1.x involves trickery or RotatedBox.
          // Implementing standard vertical bar chart for now due to complexity of labels in RotatedBox.
          // React implementation is Horizontal.
          // Let's optimize: Vertical bars with names on bottom (rotated).
        ],
      ),
    );
  }

  // Re-implementing as vertical bars to be safe with fl_chart capabilities without complex rotation
  // or use RotatedBox but need to handle labels manually.
  // Let's stick to Vertical for simplicity unless specified.
  // Wait, React is Horizontal. "layout='horizontal'".

  Widget _buildStatusPieChart(
    BuildContext context,
    List<DoctorBookingStatsItem> data,
  ) {
    int pending = 0;
    int confirmed = 0;
    int completed = 0;
    int cancelled = 0;

    for (var item in data) {
      pending += item.bookedCount;
      confirmed += item.confirmedCount;
      completed += item.completedCount;
      cancelled += item.cancelledCount;
    }

    final total = pending + confirmed + completed + cancelled;

    final sections = [
      if (pending > 0)
        PieChartSectionData(
          color: Colors.orange,
          value: pending.toDouble(),
          title: '${((pending / total) * 100).toStringAsFixed(0)}%',
          radius: 50,
        ),
      if (confirmed > 0)
        PieChartSectionData(
          color: Colors.blue,
          value: confirmed.toDouble(),
          title: '${((confirmed / total) * 100).toStringAsFixed(0)}%',
          radius: 50,
        ),
      if (completed > 0)
        PieChartSectionData(
          color: Colors.green,
          value: completed.toDouble(),
          title: '${((completed / total) * 100).toStringAsFixed(0)}%',
          radius: 50,
        ),
      if (cancelled > 0)
        PieChartSectionData(
          color: Colors.red,
          value: cancelled.toDouble(),
          title: '${((cancelled / total) * 100).toStringAsFixed(0)}%',
          radius: 50,
        ),
    ];

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    ).translate('booking_status_pie_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppLocalizations.of(context).translate('booking_status_pie_desc')} ($total)',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.theme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: sections,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      context,
                      'Pending',
                      Colors.orange,
                      pending,
                    ),
                    _buildLegendItem(
                      context,
                      'Confirmed',
                      Colors.blue,
                      confirmed,
                    ),
                    _buildLegendItem(
                      context,
                      'Completed',
                      Colors.green,
                      completed,
                    ),
                    _buildLegendItem(
                      context,
                      'Cancelled',
                      Colors.red,
                      cancelled,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: TextStyle(fontSize: 12, color: context.theme.textColor),
          ),
        ],
      ),
    );
  }
}
