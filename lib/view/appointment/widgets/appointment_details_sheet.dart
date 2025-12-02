import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
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
    final theme = Theme.of(context);
    final DateFormat timeFormatter = DateFormat('HH:mm');
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'BN: ${appointment.patient.fullName}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(theme),
            ],
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.person_outline,
            'Bác sĩ:',
            appointment.doctor.name ?? 'N/A',
          ),
          _buildDetailRow(
            Icons.calendar_today_outlined,
            'Ngày:',
            dateFormatter.format(appointment.appointmentStartTime),
          ),
          _buildDetailRow(
            Icons.access_time_outlined,
            'Giờ:',
            '${timeFormatter.format(appointment.appointmentStartTime)} - ${timeFormatter.format(appointment.appointmentEndTime)}',
          ),
          if (appointment.priceAmount != null)
            _buildDetailRow(
              Icons.attach_money,
              'Giá:',
              '${NumberFormat('#,###').format(appointment.priceAmount)} ${appointment.currency ?? 'VND'}',
            ),
          const SizedBox(height: 8),
          Text(
            'Lý do khám:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(appointment.reason ?? 'Không có'),
          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Ghi chú:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(appointment.notes!),
          ],
          const SizedBox(height: 24),
          _buildActionButtons(context),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color badgeColor;
    String statusText;

    switch (appointment.status) {
      case 'BOOKED':
        badgeColor = Colors.blue;
        statusText = 'Đã đặt';
        break;
      case 'CONFIRMED':
        badgeColor = Colors.green;
        statusText = 'Đã xác nhận';
        break;
      case 'COMPLETED':
        badgeColor = Colors.teal;
        statusText = 'Hoàn thành';
        break;
      case 'CANCELLED':
      case 'CANCELLED_BY_STAFF':
      case 'CANCELLED_BY_PATIENT':
        badgeColor = Colors.red;
        statusText = 'Đã hủy';
        break;
      case 'RESCHEDULED':
        badgeColor = Colors.orange;
        statusText = 'Đã dời';
        break;
      default:
        badgeColor = Colors.grey;
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

  Widget _buildActionButtons(BuildContext context) {
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
            label: const Text('Xác nhận'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
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
          label: const Text('Cập nhật'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
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
          label: const Text('Dời lịch'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
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
          label: const Text('Hủy'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
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
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlightColor ?? Colors.black,
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
