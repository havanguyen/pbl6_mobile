import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
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
          Text(
            'BN: ${appointment.patient.fullName}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 16),
          _buildDetailRow(
            Icons.person_outline,
            'Bác sĩ:',
            appointment.doctor.name ?? 'N/A',
          ),
          _buildDetailRow(
            Icons.bookmark_border,
            'Trạng thái:',
            appointment.status,
            highlightColor: highlightColor,
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
          const SizedBox(height: 8),
          Text(
            'Lý do khám:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(appointment.reason ?? 'Không có'),
          const SizedBox(height: 16),
          _buildActionButtons(context),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    // Watch for changes to update loading state
    final vm = context.watch<AppointmentVm>();
    final isLoading = vm.isActionLoading(appointment.id);

    // Only show actions for active appointments
    if (appointment.status != 'BOOKED' && appointment.status != 'RESCHEDULED') {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: isLoading ? null : () => _showCancelDialog(context),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Hủy'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: isLoading ? null : () => _showRescheduleDialog(context),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.schedule, size: 18),
          label: const Text('Dời lịch'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
        ),
        ElevatedButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  final success = await vm.completeAppointment(appointment.id);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã hoàn thành lịch hẹn')),
                    );
                  } else if (context.mounted && vm.actionError != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(vm.actionError!)));
                  }
                },
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Hoàn thành'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Consumer<AppointmentVm>(
        builder: (context, vm, child) {
          final isLoading = vm.isActionLoading(appointment.id);
          return AlertDialog(
            title: const Text('Hủy lịch hẹn'),
            content: TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Lý do hủy',
                hintText: 'Nhập lý do...',
              ),
              maxLines: 3,
              enabled: !isLoading,
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (reasonController.text.isEmpty) return;
                        final success = await vm.cancelAppointment(
                          appointment.id,
                          reasonController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close bottom sheet
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã hủy lịch hẹn')),
                          );
                        } else if (context.mounted && vm.actionError != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(vm.actionError!)),
                          );
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Xác nhận hủy'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRescheduleDialog(BuildContext context) {
    final startController = TextEditingController(
      text: DateFormat('HH:mm').format(appointment.appointmentStartTime),
    );
    final endController = TextEditingController(
      text: DateFormat('HH:mm').format(appointment.appointmentEndTime),
    );

    showDialog(
      context: context,
      builder: (context) => Consumer<AppointmentVm>(
        builder: (context, vm, child) {
          final isLoading = vm.isActionLoading(appointment.id);
          return AlertDialog(
            title: const Text('Dời lịch hẹn'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: startController,
                  decoration: const InputDecoration(
                    labelText: 'Giờ bắt đầu (HH:mm)',
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: endController,
                  decoration: const InputDecoration(
                    labelText: 'Giờ kết thúc (HH:mm)',
                  ),
                  enabled: !isLoading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final success = await vm.rescheduleAppointment(
                          appointment.id,
                          startController.text,
                          endController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Close bottom sheet
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã dời lịch hẹn')),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                vm.actionError ?? 'Lỗi khi dời lịch',
                              ),
                            ),
                          );
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu thay đổi'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value, {
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: highlightColor,
                fontWeight: highlightColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
