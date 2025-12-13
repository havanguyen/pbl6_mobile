import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/view/dashboard/widgets/recent_sales.dart';
import 'package:pbl6mobile/view/dashboard/widgets/revenue_chart.dart';
import 'package:pbl6mobile/view/dashboard/widgets/stat_card.dart';
import 'package:pbl6mobile/view_model/stats/stats_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import '../../../../shared/widgets/animations/fade_in_up.dart';
import '../../../../shared/localization/app_localizations.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatsVm>(
      builder: (context, vm, child) {
        // Format Total Revenue
        final totalRevenue = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '₫',
        ).format(vm.totalRevenue);

        // Stat Cards Layout
        // Grid View is tricky inside List View, so use Wrap or Column+Rows
        // Or GridView.count with shrinkWrap
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Stat Cards Grid ---
              LayoutBuilder(
                builder: (context, constraints) {
                  // Simple 2x2 grid logic if width allows, otherwise 1 col
                  int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                  double childAspectRatio = crossAxisCount == 4 ? 1.4 : 1.1;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: childAspectRatio,
                    children: [
                      // Total Staff
                      FadeInUp(
                        delay: const Duration(milliseconds: 100),
                        child: StatCard(
                          title: AppLocalizations.of(
                            context,
                          ).translate('total_staffs'),
                          value: vm.staffStats?.total.toString() ?? '0',
                          subtitle:
                              '${vm.staffStats?.recentlyCreated ?? 0} ${AppLocalizations.of(context).translate('recently_created')}',
                          icon: Icons.people,
                          iconColor: Colors.blue,
                          isLoading: vm.isLoadingStaff,
                        ),
                      ),
                      // Total Patients
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: StatCard(
                          title: AppLocalizations.of(
                            context,
                          ).translate('total_patients'),
                          value:
                              vm.patientStats?.totalPatients.toString() ?? '0',
                          subtitle:
                              '+${vm.patientStats?.currentMonthPatients ?? 0} ${AppLocalizations.of(context).translate('new_this_month')}',
                          icon: Icons.person_outline,
                          iconColor: Colors.orange,
                          isLoading: vm.isLoadingPatients,
                        ),
                      ),
                      // Appointments
                      FadeInUp(
                        delay: const Duration(milliseconds: 300),
                        child: StatCard(
                          title: AppLocalizations.of(
                            context,
                          ).translate('appointments'),
                          value:
                              vm.appointmentStats?.totalAppointments
                                  .toString() ??
                              '0',
                          subtitle: _formatGrowth(
                            context,
                            vm.appointmentStats?.growthPercent ?? 0,
                          ),
                          icon: Icons.calendar_today,
                          iconColor: Colors.pink,
                          isLoading: vm.isLoadingAppointments,
                        ),
                      ),
                      // Revenue
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: StatCard(
                          title: AppLocalizations.of(
                            context,
                          ).translate('total_revenue'),
                          value: totalRevenue,
                          subtitle:
                              'Year to date', // TODO: Localize 'year_to_date' if needed.
                          icon: Icons.attach_money,
                          iconColor: Colors.green,
                          isLoading: vm.isLoadingRevenue,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // --- Overview Chart & Recent Sales ---
              // On mobile, stack them vertically.

              // Chart Section
              FadeInUp(
                delay: const Duration(milliseconds: 500),
                child: Container(
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
                        AppLocalizations.of(context).translate('overview'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 300,
                        child: vm.isLoadingRevenue
                            ? const Center(child: CircularProgressIndicator())
                            : RevenueChart(data: vm.revenueStats),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Recent Sales (Top Doctors)
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.theme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.theme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            ).translate('top_doctors_revenue'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.theme.textColor,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(
                              context,
                            ).translate('highest_earning_doctors'),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.theme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      vm.isLoadingTopDoctors
                          ? const Center(child: CircularProgressIndicator())
                          : RecentSales(data: vm.revenueByDoctorStats),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatGrowth(BuildContext context, double growth) {
    if (growth > 0)
      return '+$growth% ${AppLocalizations.of(context).translate('from_last_month')}';
    return '$growth% ${AppLocalizations.of(context).translate('from_last_month')}';
  }
}
