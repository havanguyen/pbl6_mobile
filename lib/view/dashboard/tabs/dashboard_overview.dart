import 'package:flutter/material.dart';
import 'package:pbl6mobile/view/dashboard/widgets/dashboard_stats_card.dart';
import 'package:pbl6mobile/view_model/stats/stats_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import '../../../../shared/localization/app_localizations.dart';
import '../../../../shared/widgets/animations/fade_in_up.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsVm>(
      builder: (context, vm, child) {
        final bookingStats = vm.doctorStats?.booking;
        final contentStats = vm.doctorStats?.content;
        final isLoading = vm.isLoadingDoctorStats;

        // Calculate Completed Rate
        String completedRate = '0%';
        if (bookingStats != null && bookingStats.total > 0) {
          final rate = (bookingStats.completedCount / bookingStats.total) * 100;
          completedRate = '${rate.toStringAsFixed(1)}%';
        }

        // Calculate Average Rating
        String avgRating = '0.0';
        if (contentStats != null) {
          avgRating = contentStats.averageRating.toStringAsFixed(1);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Booking Stats ---
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppLocalizations.of(context).translate('booking_stats'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                ),
              ),
              _buildGrid(
                children: [
                  DashboardStatsCard(
                    title: AppLocalizations.of(
                      context,
                    ).translate('total_appointments'),
                    value: bookingStats?.total.toString() ?? '0',
                    description: AppLocalizations.of(
                      context,
                    ).translate('new_this_month'), // Placeholder or real logic
                    icon: Icons.calendar_today,
                    isLoading: isLoading,
                  ),
                  DashboardStatsCard(
                    title: AppLocalizations.of(
                      context,
                    ).translate('pending_confirmation'),
                    value: bookingStats?.bookedCount.toString() ?? '0',
                    description: AppLocalizations.of(
                      context,
                    ).translate('from_last_month'), // Placeholder
                    icon: Icons.timer, // loading/pending icon
                    isLoading: isLoading,
                    iconColor: Colors.orange,
                  ),
                  DashboardStatsCard(
                    title: AppLocalizations.of(context).translate('confirmed'),
                    value: bookingStats?.confirmedCount.toString() ?? '0',
                    description: AppLocalizations.of(
                      context,
                    ).translate('from_last_month'),
                    icon: Icons.check_circle_outline,
                    isLoading: isLoading,
                    iconColor: Colors.blue,
                  ),
                  DashboardStatsCard(
                    title: AppLocalizations.of(
                      context,
                    ).translate('completed_rate'),
                    value: completedRate,
                    description: AppLocalizations.of(
                      context,
                    ).translate('from_last_month'),
                    icon: Icons.pie_chart,
                    isLoading: isLoading,
                    iconColor: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Content Stats ---
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppLocalizations.of(context).translate('content_stats'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                ),
              ),
              _buildGrid(
                children: [
                  DashboardStatsCard(
                    title: AppLocalizations.of(context).translate('reviews'),
                    value: contentStats?.totalReviews.toString() ?? '0',
                    description: AppLocalizations.of(
                      context,
                    ).translate('new_this_month'),
                    icon: Icons.star_border,
                    isLoading: isLoading,
                  ),
                  DashboardStatsCard(
                    title: AppLocalizations.of(context).translate('avg_rating'),
                    value: avgRating,
                    description: AppLocalizations.of(
                      context,
                    ).translate('from_last_month'),
                    icon: Icons.star,
                    isLoading: isLoading,
                    iconColor: Colors.yellow[700],
                  ),
                  DashboardStatsCard(
                    title: AppLocalizations.of(context).translate('qa_answers'),
                    value: contentStats?.totalAnswers.toString() ?? '0',
                    description:
                        '${contentStats?.totalAcceptedAnswers ?? 0} ${AppLocalizations.of(context).translate('accepted_answers')}',
                    icon: Icons.question_answer_outlined,
                    isLoading: isLoading,
                    iconColor: Colors.purple,
                  ),
                  DashboardStatsCard(
                    title: AppLocalizations.of(
                      context,
                    ).translate('published_blogs'),
                    value:
                        contentStats?.totalBlogs.toString() ??
                        '0', // Assuming totalBlogs exists in ContentStats
                    description: AppLocalizations.of(
                      context,
                    ).translate('new_this_month'),
                    icon: Icons.article_outlined,
                    isLoading: isLoading,
                    iconColor: Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- Bottom Cards ---
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    crossAxisCount: constraints.maxWidth > 600 ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 2.0,
                    children: [
                      // Booking Performance Card
                      _buildPerformanceCard(
                        context,
                        title: AppLocalizations.of(
                          context,
                        ).translate('booking_performance'),
                        subtitle: 'Details about appointment status',
                        items: [
                          _PerformanceItem(
                            label: AppLocalizations.of(
                              context,
                            ).translate('status_completed'),
                            value:
                                bookingStats?.completedCount.toString() ?? '0',
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          _PerformanceItem(
                            label: AppLocalizations.of(
                              context,
                            ).translate('status_confirmed'),
                            value:
                                bookingStats?.confirmedCount.toString() ?? '0',
                            icon: Icons.access_time,
                            color: Colors.orange,
                          ),
                          _PerformanceItem(
                            label: AppLocalizations.of(
                              context,
                            ).translate('status_cancelled'),
                            value:
                                bookingStats?.cancelledCount.toString() ?? '0',
                            icon: Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      // Content Engagement Card
                      _buildPerformanceCard(
                        context,
                        title: AppLocalizations.of(
                          context,
                        ).translate('content_engagement'),
                        subtitle: 'Engagement with posts and answers',
                        items: [
                          _PerformanceItem(
                            label: AppLocalizations.of(
                              context,
                            ).translate('avg_rating'),
                            value: '$avgRating / 5.0',
                            icon: Icons.star,
                            color: Colors.amber,
                          ),
                          _PerformanceItem(
                            label: AppLocalizations.of(
                              context,
                            ).translate('accepted_answers'),
                            value:
                                '${contentStats?.totalAcceptedAnswers ?? 0} / ${contentStats?.totalAnswers ?? 0}',
                            icon: Icons.message_outlined,
                            color: Colors.blue,
                          ),
                          _PerformanceItem(
                            label: AppLocalizations.of(
                              context,
                            ).translate('published_blogs'),
                            value: contentStats?.totalBlogs.toString() ?? '0',
                            icon: Icons.article_outlined,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<_PerformanceItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.theme.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: context.theme.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(item.icon, size: 16, color: item.color),
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.theme.textColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        double childAspectRatio = crossAxisCount == 4 ? 1.4 : 1.3;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: children,
        );
      },
    );
  }
}

class _PerformanceItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _PerformanceItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
