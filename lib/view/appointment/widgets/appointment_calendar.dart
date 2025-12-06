import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/view/appointment/widgets/appointment_details_sheet.dart';
import 'package:pbl6mobile/view_model/appointment/appointment_vm.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AppointmentCalendar extends StatelessWidget {
  final CalendarController controller;
  final CalendarView currentView;
  final Function(ViewChangedDetails) onViewChanged;

  const AppointmentCalendar({
    super.key,
    required this.controller,
    required this.currentView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppointmentVm>();
    final nonWorkingDays = <int>[];
    vm.workingDays.forEach((day, isWorking) {
      if (!isWorking) nonWorkingDays.add(day);
    });

    return SfCalendar(
      controller: controller,
      view: currentView,
      dataSource: vm.dataSource,
      firstDayOfWeek: 1,
      viewHeaderStyle: ViewHeaderStyle(
        dayTextStyle: TextStyle(color: context.theme.mutedForeground),
        dateTextStyle: TextStyle(
          color: context.theme.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      headerStyle: CalendarHeaderStyle(
        textStyle: TextStyle(
          color: context.theme.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: context.theme.bg,
      ),
      todayHighlightColor: context.theme.primary,
      selectionDecoration: BoxDecoration(
        border: Border.all(color: context.theme.primary, width: 2),
      ),
      timeSlotViewSettings: TimeSlotViewSettings(
        startHour: vm.startHour,
        endHour: vm.endHour,
        nonWorkingDays: nonWorkingDays,
        dateFormat: 'd',
        dayFormat: 'EEE',
        timeFormat: 'HH:mm',
        timeIntervalHeight: 60,
        timeTextStyle: TextStyle(color: context.theme.mutedForeground),
      ),
      scheduleViewSettings: ScheduleViewSettings(
        appointmentItemHeight: 90,
        monthHeaderSettings: MonthHeaderSettings(
          monthFormat: 'MMMM, yyyy',
          height: 70,
          textAlign: TextAlign.left,
          backgroundColor: context.theme.bg,
          monthTextStyle: TextStyle(
            color: context.theme.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      monthViewSettings: MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
        showAgenda: true,
        agendaStyle: AgendaStyle(
          backgroundColor: context.theme.bg,
          dateTextStyle: TextStyle(
            color: context.theme.textColor,
            fontWeight: FontWeight.bold,
          ),
          dayTextStyle: TextStyle(
            color: context.theme.mutedForeground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onViewChanged: (ViewChangedDetails details) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onViewChanged(details);
        });
      },
      onTap: (CalendarTapDetails details) {
        if (details.targetElement == CalendarElement.appointment) {
          final AppointmentData appointment = details.appointments!.first;
          final color = _getStatusColor(context, appointment.status);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => AppointmentDetailsSheet(
              appointment: appointment,
              highlightColor: color,
            ),
          );
        }
      },
      appointmentBuilder: (context, calendarAppointmentDetails) {
        final AppointmentData appointment =
            calendarAppointmentDetails.appointments.first;

        if (currentView == CalendarView.schedule) {
          return _buildScheduleCard(context, appointment);
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (vm.badgeVariant == 'dot') {
              return _buildDotBadge(
                context,
                appointment,
                currentView,
                constraints,
              );
            } else if (vm.badgeVariant == 'mixed') {
              return _buildMixedBadge(
                context,
                appointment,
                currentView,
                constraints,
              );
            }
            return _buildColoredBadge(
              context,
              appointment,
              currentView,
              constraints,
            );
          },
        );
      },
    );
  }

  Widget _buildScheduleCard(BuildContext context, AppointmentData appointment) {
    final color = _getStatusColor(context, appointment.status);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: context.theme.popover.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${appointment.appointmentStartTime.hour}:${appointment.appointmentStartTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.theme.textColor,
                  ),
                ),
                Text(
                  '${appointment.appointmentEndTime.hour}:${appointment.appointmentEndTime.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: context.theme.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    appointment.patient.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 14,
                        color: context.theme.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          appointment.doctor.name ?? 'N/A',
                          style: TextStyle(
                            color: context.theme.mutedForeground,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                appointment.status,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColoredBadge(
    BuildContext context,
    AppointmentData appointment,
    CalendarView view,
    BoxConstraints constraints,
  ) {
    final color = _getStatusColor(context, appointment.status);
    final isSmall = constraints.maxHeight < 40;
    final isMedium = constraints.maxHeight < 60;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: context.theme.popover.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: isSmall ? 0 : 2),
      child: isSmall
          ? Center(
              child: Text(
                appointment.patient.fullName,
                style: TextStyle(
                  color: context.theme.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  appointment.patient.fullName,
                  style: TextStyle(
                    color: context.theme.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (!isMedium && view != CalendarView.month) ...[
                  const SizedBox(height: 2),
                  Text(
                    'BS: ${appointment.doctor.name ?? 'N/A'}',
                    style: TextStyle(
                      color: context.theme.white.withOpacity(0.7),
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildDotBadge(
    BuildContext context,
    AppointmentData appointment,
    CalendarView view,
    BoxConstraints constraints,
  ) {
    final color = _getStatusColor(context, appointment.status);
    final isSmall = constraints.maxHeight < 40;

    return Container(
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.theme.border),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: isSmall ? 0 : 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              appointment.patient.fullName,
              style: TextStyle(
                color: context.theme.textColor,
                fontSize: isSmall ? 9 : 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixedBadge(
    BuildContext context,
    AppointmentData appointment,
    CalendarView view,
    BoxConstraints constraints,
  ) {
    final color = _getStatusColor(context, appointment.status);
    final isSmall = constraints.maxHeight < 40;
    final isMedium = constraints.maxHeight < 60;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: isSmall ? 0 : 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            appointment.patient.fullName,
            style: TextStyle(
              color: context.theme.textColor,
              fontSize: isSmall ? 9 : 11,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          if (!isMedium && !isSmall && view != CalendarView.month) ...[
            const SizedBox(height: 1),
            Flexible(
              child: Text(
                'BS: ${appointment.doctor.name ?? 'N/A'}',
                style: TextStyle(
                  color: context.theme.mutedForeground,
                  fontSize: 9,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'BOOKED':
        return context.theme.blue;
      case 'COMPLETED':
        return context.theme.green;
      case 'CANCELLED':
      case 'CANCELLED_BY_STAFF':
      case 'CANCELLED_BY_PATIENT':
        return context.theme.destructive;
      case 'RESCHEDULED':
        return context.theme.yellow;
      default:
        return context.theme.muted;
    }
  }
}
