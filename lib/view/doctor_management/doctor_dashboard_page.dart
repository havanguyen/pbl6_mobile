import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/view_model/doctor_dashboard_vm.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:intl/intl.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorDashboardVm>().initData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('doctor_dashboard')),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: AppLocalizations.of(context).translate('overview')),
            Tab(text: AppLocalizations.of(context).translate('appointments')),
          ],
        ),
      ),
      body: Consumer<DoctorDashboardVm>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.error != null) {
            return Center(child: Text('Error: ${vm.error}'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, vm),
              _buildAppointmentsTab(context, vm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, DoctorDashboardVm vm) {
    final stats = vm.doctorStats;
    if (stats == null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).translate('no_stats_available'),
          style: TextStyle(color: context.theme.textColor),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).translate('booking_stats'),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                context,
                AppLocalizations.of(
                  context,
                ).translate('total_appointments_stat'),
                stats.booking.total.toString(),
                Icons.calendar_today,
                Colors.blue,
              ),
              _buildStatCard(
                context,
                AppLocalizations.of(context).translate('pending_conf'),
                stats.booking.bookedCount.toString(),
                Icons.access_time,
                Colors.orange,
              ),
              _buildStatCard(
                context,
                AppLocalizations.of(context).translate('confirmed_stat'),
                stats.booking.confirmedCount.toString(),
                Icons.check_circle,
                context.theme.green,
              ),
              _buildStatCard(
                context,
                AppLocalizations.of(context).translate('completed_rate'),
                '${stats.booking.completedRate.toStringAsFixed(1)}%',
                Icons.task_alt,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            AppLocalizations.of(context).translate('content_stats'),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                context,
                AppLocalizations.of(context).translate('total_reviews'),
                stats.content.totalReviews.toString(),
                Icons.star_outline,
                Colors.amber,
              ),
              _buildStatCard(
                context,
                AppLocalizations.of(context).translate('avg_rating'),
                stats.content.averageRating.toStringAsFixed(1),
                Icons.star,
                Colors.yellow,
              ),
              _buildStatCard(
                context,
                AppLocalizations.of(context).translate('qa_answers'),
                stats.content.totalAnswers.toString(),
                Icons.question_answer,
                Colors.indigo,
              ),
              _buildStatCard(
                context,
                AppLocalizations.of(context).translate('total_blogs'),
                stats.content.totalBlogs.toString(),
                Icons.article,
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsTab(BuildContext context, DoctorDashboardVm vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            '${AppLocalizations.of(context).translate('pending_confirmation_header')} (${vm.pendingTotal})',
            icon: Icons.access_time_filled,
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          if (vm.pendingAppointments.isEmpty)
            _buildEmptyState(
              AppLocalizations.of(context).translate('no_pending_appointments'),
              context,
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.pendingAppointments.length,
              itemBuilder: (context, index) {
                final apt = vm.pendingAppointments[index];
                return _buildAppointmentCard(context, apt, isPending: true);
              },
            ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            context,
            '${AppLocalizations.of(context).translate('upcoming_header')} (${vm.upcomingTotal})',
            icon: Icons.calendar_today,
            color: context.theme.green,
          ),
          const SizedBox(height: 8),
          if (vm.upcomingAppointments.isEmpty)
            _buildEmptyState(
              AppLocalizations.of(
                context,
              ).translate('no_upcoming_appointments'),
              context,
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: vm.upcomingAppointments.length,
              itemBuilder: (context, index) {
                final apt = vm.upcomingAppointments[index];
                return _buildAppointmentCard(context, apt);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    IconData? icon,
    Color? color,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.theme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: context.theme.mutedForeground ?? Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        ),
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
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
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

  Widget _buildAppointmentCard(
    BuildContext context,
    dynamic apt, {
    bool isPending = false,
  }) {
    // apt is AppointmentData. Fields are already DateTimes.
    final date = apt.event.serviceDate ?? DateTime.now();
    final startTime = apt.event.timeStart ?? DateTime.now();
    final endTime = apt.event.timeEnd ?? DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    final timeFormatter = DateFormat('HH:mm');

    // Use theme-aware colors for better contrast
    // For pending card:
    // Light Mode: Colors.orange.shade50 (Light orange)
    // Dark Mode: Colors.orange.withOpacity(0.15) (Darker orange tint) to ensure white text is visible
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isPending
        ? (isDark ? Colors.orange.withOpacity(0.15) : Colors.orange.shade50)
        : context.theme.card;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isPending
                      ? Colors.orange
                      : context.theme.green,
                  radius: 20,
                  child: Icon(
                    Icons.person,
                    color: context.theme.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apt.patient.fullName.isNotEmpty
                            ? apt.patient.fullName
                            : (AppLocalizations.of(
                                context,
                              ).translate('unknown_patient')),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.theme.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: context.theme.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatter.format(date),
                            style: TextStyle(
                              fontSize: 13,
                              color: context.theme.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: context.theme.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${timeFormatter.format(startTime)} - ${timeFormatter.format(endTime)}',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.theme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (apt.reason != null && apt.reason!.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: context.theme.mutedForeground,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      apt.reason!,
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: context.theme.textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
