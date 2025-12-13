import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/stats/stats.types.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import '../../../../shared/localization/app_localizations.dart';

class RevenueChart extends StatelessWidget {
  final List<RevenueStats> data;

  const RevenueChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).translate('no_data'),
          style: TextStyle(color: context.theme.mutedForeground),
        ),
      );
    }

    return BarChart(
      BarChartData(
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.theme.popover,
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[groupIndex].name}\n',
                TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: (rod.toY).toStringAsFixed(0),
                    style: TextStyle(
                      color: context.theme.primary,
                      fontSize: 14,
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
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < 0 || value.toInt() >= data.length) {
                  return const SizedBox.shrink();
                }
                // Shorten "Jan 2025" to "Jan"
                final fullName = data[value.toInt()].name;
                final shortName = fullName.split(' ').first;

                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    shortName,
                    style: TextStyle(
                      color: context.theme.mutedForeground,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  _formatYAxis(value),
                  style: TextStyle(
                    color: context.theme.mutedForeground,
                    fontSize: 10,
                  ),
                );
              },
              reservedSize: 40,
              interval: _calculateInterval(data),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: context.theme.border,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final value = (item.total['VND'] ?? 0).toDouble();

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                gradient: LinearGradient(
                  colors: [
                    context.theme.primary.withOpacity(0.8),
                    context.theme.primary,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 350), // Animation
      swapAnimationCurve: Curves.linearToEaseOut,
    );
  }

  String _formatYAxis(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  double? _calculateInterval(List<RevenueStats> data) {
    if (data.isEmpty) return null;
    double max = 0;
    for (var item in data) {
      final val = (item.total['VND'] ?? 0).toDouble();
      if (val > max) max = val;
    }
    if (max == 0) return 100;
    // Aim for about 5 ticks
    return max / 5;
  }
}
