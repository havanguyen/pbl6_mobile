import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/view/appointment/widgets/appointment_action_dialogs.dart';
import 'package:pbl6mobile/view_model/appointment/appointment_vm.dart';
import 'package:provider/provider.dart';

class AppointmentDetailsSheet extends StatelessWidget {
  final AppointmentData appointment;
  final Color highlightColor;

  const AppointmentDetailsSheet({
    super.key,
    required this.appointment,
    required this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final DateFormat timeFormatter = DateFormat('HH:mm');
    final DateFormat dateFormatter = DateFormat('EEEE, dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.muted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.patient.fullName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: theme.textColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).translate('patient'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildStatusBadge(context, theme),
            ],
          ),

          const SizedBox(height: 24),
          Divider(height: 1, color: theme.border.withOpacity(0.5)),
          const SizedBox(height: 24),

          // Details Section
          _buildDetailRow(
            context,
            theme,
            Icons.medical_services_outlined,
            AppLocalizations.of(context).translate('doctor'),
            appointment.doctor.name ?? 'Unassigned',
            highlight: true,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            theme,
            Icons.calendar_month_outlined,
            AppLocalizations.of(context).translate('date_label'),
            dateFormatter.format(appointment.appointmentStartTime),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            context,
            theme,
            Icons.access_time_outlined,
            AppLocalizations.of(context).translate('time'),
            '${timeFormatter.format(appointment.appointmentStartTime)} - ${timeFormatter.format(appointment.appointmentEndTime)}',
          ),
          if (appointment.priceAmount != null) ...[
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              theme,
              Icons.attach_money,
              AppLocalizations.of(context).translate('price'),
              '${NumberFormat('#,###').format(appointment.priceAmount)} ${appointment.currency ?? 'VND'}',
              valueColor: theme.primary,
            ),
          ],

          const SizedBox(height: 24),

          // Additional Info Check
          if ((appointment.reason != null && appointment.reason!.isNotEmpty) ||
              (appointment.notes != null && appointment.notes!.isNotEmpty))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.muted.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (appointment.reason != null &&
                      appointment.reason!.isNotEmpty) ...[
                    Text(
                      '${AppLocalizations.of(context).translate('reason')}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.reason!,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (appointment.notes != null &&
                      appointment.notes!.isNotEmpty) ...[
                    if (appointment.reason != null &&
                        appointment.reason!.isNotEmpty)
                      const SizedBox(height: 12),
                    Text(
                      '${AppLocalizations.of(context).translate('notes')}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.notes!,
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 32),
          _buildActionButtons(context, theme),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.mutedForeground,
                side: BorderSide(color: theme.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context).translate('close'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, CustomThemeExtension theme) {
    Color badgeColor;
    String statusText;

    switch (appointment.status) {
      case 'BOOKED':
        badgeColor = const Color(0xFF3B82F6);
        statusText = AppLocalizations.of(context).translate('status_booked');
        break;
      case 'CONFIRMED':
        badgeColor = const Color(0xFF10B981);
        statusText = AppLocalizations.of(context).translate('status_confirmed');
        break;
      case 'COMPLETED':
        badgeColor = const Color(0xFF059669);
        statusText = AppLocalizations.of(context).translate('status_completed');
        break;
      case 'CANCELLED':
      case 'CANCELLED_BY_STAFF':
      case 'CANCELLED_BY_PATIENT':
        badgeColor = const Color(0xFFEF4444);
        statusText = AppLocalizations.of(context).translate('status_cancelled');
        break;
      case 'RESCHEDULED':
        badgeColor = const Color(0xFFF59E0B);
        statusText = AppLocalizations.of(
          context,
        ).translate('status_rescheduled');
        break;
      default:
        badgeColor = theme.mutedForeground;
        statusText = appointment.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: badgeColor.withOpacity(0.2)),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CustomThemeExtension theme) {
    final vm = context.watch<AppointmentVm>();
    final isLoading = vm.isActionLoading(appointment.id);

    // Only show actions for active appointments
    if (appointment.status != 'BOOKED' &&
        appointment.status != 'RESCHEDULED' &&
        appointment.status != 'CONFIRMED') {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        if (appointment.status == 'BOOKED' ||
            appointment.status == 'RESCHEDULED')
          _buildActionButton(
            context: context,
            label: AppLocalizations.of(context).translate('confirm'),
            icon: Icons.check_circle_outline,
            color: const Color(0xFF10B981),
            onPressed: isLoading
                ? null
                : () => AppointmentActionDialogs.showConfirmDialog(
                    context,
                    appointment,
                  ),
          ),

        _buildActionButton(
          context: context,
          label: AppLocalizations.of(context).translate('update'),
          icon: Icons.edit_outlined,
          color: const Color(0xFF3B82F6),
          onPressed: isLoading
              ? null
              : () => AppointmentActionDialogs.showEditDialog(
                  context,
                  appointment,
                ),
        ),

        _buildActionButton(
          context: context,
          label: AppLocalizations.of(context).translate('reschedule'),
          icon: Icons.access_time, // Use generic time icon
          color: const Color(0xFFF59E0B),
          onPressed: isLoading
              ? null
              : () => AppointmentActionDialogs.showRescheduleDialog(
                  context,
                  appointment,
                ),
        ),

        _buildActionButton(
          context: context,
          label: AppLocalizations.of(context).translate('cancel'),
          icon: Icons.cancel_outlined,
          color: const Color(0xFFEF4444),
          onPressed: isLoading
              ? null
              : () => AppointmentActionDialogs.showCancelDialog(
                  context,
                  appointment,
                ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    CustomThemeExtension theme,
    IconData icon,
    String title,
    String value, {
    Color? valueColor,
    bool highlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.muted.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: theme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: valueColor ?? theme.textColor,
                  fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
