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
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.muted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${AppLocalizations.of(context).translate('patient')}: ${appointment.patient.fullName}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textColor,
                  ),
                ),
              ),
              _buildStatusBadge(context, theme),
            ],
          ),
          Divider(height: 24, color: theme.border),
          _buildDetailRow(
            context,
            theme,
            Icons.person_outline,
            AppLocalizations.of(context).translate('doctor'),
            appointment.doctor.name ?? 'N/A',
          ),
          _buildDetailRow(
            context,
            theme,
            Icons.calendar_today_outlined,
            AppLocalizations.of(context).translate('date_label'),
            dateFormatter.format(appointment.appointmentStartTime),
          ),
          _buildDetailRow(
            context,
            theme,
            Icons.access_time_outlined,
            AppLocalizations.of(context).translate('time'),
            '${timeFormatter.format(appointment.appointmentStartTime)} - ${timeFormatter.format(appointment.appointmentEndTime)}',
          ),
          if (appointment.priceAmount != null)
            _buildDetailRow(
              context,
              theme,
              Icons.attach_money,
              AppLocalizations.of(context).translate('price'),
              '${NumberFormat('#,###').format(appointment.priceAmount)} ${appointment.currency ?? 'VND'}',
            ),
          const SizedBox(height: 12),
          Text(
            '${AppLocalizations.of(context).translate('reason')}:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textColor,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            appointment.reason ??
                AppLocalizations.of(context).translate('none'),
            style: TextStyle(color: theme.mutedForeground),
          ),
          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${AppLocalizations.of(context).translate('notes')}:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.textColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appointment.notes!,
              style: TextStyle(color: theme.mutedForeground),
            ),
          ],
          const SizedBox(height: 24),
          _buildActionButtons(context, theme),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.mutedForeground,
                side: BorderSide(color: theme.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppLocalizations.of(context).translate('close')),
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
        badgeColor = theme.blue;
        statusText = AppLocalizations.of(context).translate('status_booked');
        break;
      case 'CONFIRMED':
        badgeColor = theme.green;
        statusText = AppLocalizations.of(context).translate('status_confirmed');
        break;
      case 'COMPLETED':
        badgeColor = theme.green;
        statusText = AppLocalizations.of(context).translate('status_completed');
        break;
      case 'CANCELLED':
      case 'CANCELLED_BY_STAFF':
      case 'CANCELLED_BY_PATIENT':
        badgeColor = theme.destructive;
        statusText = AppLocalizations.of(context).translate('status_cancelled');
        break;
      case 'RESCHEDULED':
        badgeColor = theme.yellow;
        statusText = AppLocalizations.of(
          context,
        ).translate('status_rescheduled');
        break;
      default:
        badgeColor = theme.mutedForeground;
        statusText = appointment.status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
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
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (appointment.status == 'BOOKED' ||
            appointment.status == 'RESCHEDULED')
          ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () => AppointmentActionDialogs.showConfirmDialog(
                    context,
                    appointment,
                  ),
            icon: const Icon(Icons.check, size: 18),
            label: Text(AppLocalizations.of(context).translate('confirm')),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.green,
              foregroundColor: theme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

        ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => AppointmentActionDialogs.showEditDialog(
                  context,
                  appointment,
                ),
          icon: const Icon(Icons.edit, size: 18),
          label: Text(AppLocalizations.of(context).translate('update')),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.blue,
            foregroundColor: theme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => AppointmentActionDialogs.showRescheduleDialog(
                  context,
                  appointment,
                ),
          icon: const Icon(Icons.schedule, size: 18),
          label: Text(AppLocalizations.of(context).translate('reschedule')),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.yellow,
            foregroundColor: theme.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () => AppointmentActionDialogs.showCancelDialog(
                  context,
                  appointment,
                ),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: Text(AppLocalizations.of(context).translate('cancel')),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.destructive,
            foregroundColor: theme.destructiveForeground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    CustomThemeExtension theme,
    IconData icon,
    String title,
    String value, {
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.mutedForeground),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: theme.mutedForeground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlightColor ?? theme.textColor,
                fontWeight: highlightColor != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
