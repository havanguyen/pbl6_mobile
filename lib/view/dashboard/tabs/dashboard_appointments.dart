import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/view/dashboard/widgets/doctor_booking_chart.dart';

class DashboardAppointments extends StatefulWidget {
  const DashboardAppointments({super.key});

  @override
  State<DashboardAppointments> createState() => _DashboardAppointmentsState();
}

class _DashboardAppointmentsState extends State<DashboardAppointments> {
  final AppointmentService _appointmentService = AppointmentService();

  List<AppointmentData> _pendingAppointments = [];
  bool _isLoadingPending = true;
  int _totalPending = 0;

  List<AppointmentData> _upcomingAppointments = [];
  bool _isLoadingUpcoming = true;
  int _totalUpcoming = 0;

  @override
  void initState() {
    super.initState();
    _fetchPendingAppointments();
    _fetchUpcomingAppointments();
  }

  Future<void> _fetchPendingAppointments() async {
    setState(() => _isLoadingPending = true);
    try {
      final now = DateTime.now();
      final fromDate = DateTime(now.year, now.month - 2, now.day);
      final toDate = DateTime(now.year, now.month + 2, now.day);

      final response = await _appointmentService.getAppointments(
        fromDate: fromDate,
        toDate: toDate,
        status: 'BOOKED',
        page: 1,
        limit: 10,
      );

      if (mounted && response != null && response.success) {
        setState(() {
          _pendingAppointments = response.data;
          _totalPending = response.meta?['total'] ?? response.data.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching pending appointments: $e');
    } finally {
      if (mounted) setState(() => _isLoadingPending = false);
    }
  }

  Future<void> _fetchUpcomingAppointments() async {
    setState(() => _isLoadingUpcoming = true);
    try {
      final now = DateTime.now();
      final toDate = now.add(const Duration(days: 2));

      final response = await _appointmentService.getAppointments(
        fromDate: now,
        toDate: toDate,
        status: 'CONFIRMED',
        page: 1,
        limit: 10,
      );

      if (mounted && response != null && response.success) {
        setState(() {
          _upcomingAppointments = response.data;
          _totalUpcoming = response.meta?['total'] ?? response.data.length;
        });
      }
    } catch (e) {
      debugPrint('Error fetching upcoming appointments: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUpcoming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DoctorBookingChart(),
          const SizedBox(height: 24),
          _buildAppointmentSection(
            context,
            title: AppLocalizations.of(
              context,
            ).translate('pending_confirmation'),
            description: AppLocalizations.of(
              context,
            ).translate('needs_confirmation'),
            appointments: _pendingAppointments,
            isLoading: _isLoadingPending,
            totalCount: _totalPending,
            icon: Icons.timer,
            iconColor: Colors.orange,
            emptyMessage: AppLocalizations.of(
              context,
            ).translate('no_pending_appointments'),
          ),
          const SizedBox(height: 24),
          _buildAppointmentSection(
            context,
            title: AppLocalizations.of(
              context,
            ).translate('upcoming_appointments'),
            description: AppLocalizations.of(
              context,
            ).translate('confirmed_next_3_days'),
            appointments: _upcomingAppointments,
            isLoading: _isLoadingUpcoming,
            totalCount: _totalUpcoming,
            icon: Icons.calendar_today,
            iconColor: Colors.green,
            emptyMessage: AppLocalizations.of(
              context,
            ).translate('no_upcoming_appointments'),
            isUpcoming: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentSection(
    BuildContext context, {
    required String title,
    required String description,
    required List<AppointmentData> appointments,
    required bool isLoading,
    required int totalCount,
    required IconData icon,
    required Color iconColor,
    required String emptyMessage,
    bool isUpcoming = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 20, color: iconColor),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.theme.textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.theme.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: iconColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    '$totalCount total',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSkeleton(context),
                  ),
                ),
              ),
            )
          else if (appointments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                emptyMessage,
                style: TextStyle(color: context.theme.mutedForeground),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: appointments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final apt = appointments[index];
                return _buildAppointmentItem(context, apt, isUpcoming);
              },
            ),
          if (!isLoading &&
              appointments.isNotEmpty &&
              totalCount > appointments.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextButton(
                onPressed: () {
                  // Navigate to full list? For now just placeholder
                },
                child: Text(
                  'View all $totalCount appointments',
                  style: TextStyle(color: context.theme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: context.theme.muted.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildAppointmentItem(
    BuildContext context,
    AppointmentData apt,
    bool isUpcoming,
  ) {
    final dateFormat = DateFormat('EEE, MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final dateStr = apt.event.serviceDate != null
        ? dateFormat.format(apt.event.serviceDate!)
        : 'N/A';
    final timeStr = apt.event.timeStart != null
        ? '${timeFormat.format(apt.event.timeStart!)} - ${apt.event.timeEnd != null ? timeFormat.format(apt.event.timeEnd!) : ""}'
        : 'N/A';

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUpcoming && isDarkMode
            ? Colors.green.withOpacity(0.1)
            : isUpcoming
            ? Colors.green.withOpacity(0.05)
            : context.theme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUpcoming
              ? Colors.green.withOpacity(0.3)
              : context.theme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: context.theme.mutedForeground,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      apt.patient.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.theme.textColor,
                      ),
                    ),
                    if (apt.patient.dateOfBirth != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(Age: ${DateTime.now().year - apt.patient.dateOfBirth!.year})',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.theme.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildStatusBadge(context, apt.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: context.theme.mutedForeground,
              ),
              const SizedBox(width: 6),
              Text(
                '$dateStr • $timeStr',
                style: TextStyle(
                  fontSize: 13,
                  color: context.theme.textColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          if (apt.reason != null && apt.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 14,
                  color: context.theme.mutedForeground,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    apt.reason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: context.theme.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color color;
    switch (status) {
      case 'BOOKED':
        color = Colors.orange;
        break;
      case 'CONFIRMED':
        color = Colors.green;
        break;
      case 'COMPLETED':
        color = Colors.blue;
        break;
      case 'CANCELLED':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
