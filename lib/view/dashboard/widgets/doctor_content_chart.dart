import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/stats/stats.types.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/view_model/stats/stats_vm.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class DoctorContentChart extends StatefulWidget {
  const DoctorContentChart({super.key});

  @override
  State<DoctorContentChart> createState() => _DoctorContentChartState();
}

class _DoctorContentChartState extends State<DoctorContentChart> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsVm>().fetchDoctorsContentStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsVm>(
      builder: (context, vm, child) {
        if (vm.isLoadingDoctorsContent) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = vm.doctorsContentStats?.data ?? [];
        if (data.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRatingChart(context, data)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildContentRadarChart(context, data)),
                ],
              );
            }
            return Column(
              children: [
                _buildRatingChart(context, data),
                const SizedBox(height: 24),
                _buildContentRadarChart(context, data),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRatingChart(
    BuildContext context,
    List<DoctorContentStatsItem> data,
  ) {
    // Top 10 by rating
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
            AppLocalizations.of(
              context,
            ).translate('content_stats_rating_title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).translate('content_stats_rating_desc'),
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
                maxY: 5,
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
                                'Rating: ${doctor.averageRating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.amber,
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
                            name.split(' ').last,
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
                          '${value.toInt()}★',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                      interval: 1,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(show: true, horizontalInterval: 1),
                borderData: FlBorderData(show: false),
                barGroups: topDoctors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.averageRating,
                        color: Colors.amber,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentRadarChart(
    BuildContext context,
    List<DoctorContentStatsItem> data,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Take top 5 for radar to avoid clutter
    final radarData = data.take(5).toList();

    // Normalize data?
    // Radar charts usually need consistent scales or normalization.
    // Let's find max values for each dimension.
    double maxReviews = 1;
    double maxAnswers = 1;
    double maxAccepted = 1;
    double maxBlogs = 1;

    for (var item in radarData) {
      maxReviews = math.max(maxReviews, item.totalReviews.toDouble());
      maxAnswers = math.max(maxAnswers, item.totalAnswers.toDouble());
      maxAccepted = math.max(maxAccepted, item.totalAcceptedAnswers.toDouble());
      maxBlogs = math.max(maxBlogs, item.totalBlogs.toDouble());
    }

    final colors = [
      Colors.amber,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.red,
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
          Text(
            AppLocalizations.of(context).translate('content_stats_radar_title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context).translate('content_stats_radar_desc'),
            style: TextStyle(
              fontSize: 12,
              color: context.theme.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                dataSets: radarData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final color = colors[index % colors.length];

                  return RadarDataSet(
                    fillColor: color.withOpacity(0.2),
                    borderColor: color,
                    entryRadius: 3,
                    dataEntries: [
                      RadarEntry(value: item.totalReviews.toDouble()),
                      RadarEntry(value: item.totalAnswers.toDouble()),
                      RadarEntry(value: item.totalAcceptedAnswers.toDouble()),
                      RadarEntry(value: item.totalBlogs.toDouble()),
                    ],
                  );
                }).toList(),
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 10,
                ),
                getTitle: (index, angle) {
                  switch (index) {
                    case 0:
                      return RadarChartTitle(text: 'Reviews');
                    case 1:
                      return RadarChartTitle(text: 'Answers');
                    case 2:
                      return RadarChartTitle(text: 'Accepted');
                    case 3:
                      return RadarChartTitle(text: 'Blogs');
                    default:
                      return RadarChartTitle(text: '');
                  }
                },
                tickCount: 5,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                gridBorderData: BorderSide(
                  color: context.theme.muted.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: radarData.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = colors[index % colors.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, color: color),
                  const SizedBox(width: 4),
                  Text(
                    item.doctor.fullName.split(' ').last,
                    style: TextStyle(
                      fontSize: 10,
                      color: context.theme.textColor,
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
}
