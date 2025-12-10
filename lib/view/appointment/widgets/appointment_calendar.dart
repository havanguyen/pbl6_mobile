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

    return RepaintBoundary(
      child: SfCalendar(
        key: const ValueKey('appointment_calendar'),
        controller: controller,
        view: currentView,
        dataSource: vm.dataSource,
        firstDayOfWeek: 1,
        viewHeaderStyle: ViewHeaderStyle(
          dayTextStyle: TextStyle(
            color: context.theme.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
          dateTextStyle: TextStyle(
            color: context.theme.textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        headerStyle: CalendarHeaderStyle(
          textStyle: TextStyle(
            color: context.theme.textColor,
            fontSize: 20,
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
          timeIntervalHeight: 70,
          timeTextStyle: TextStyle(
            color: context.theme.mutedForeground,
            fontSize: 12,
          ),
        ),
        scheduleViewSettings: ScheduleViewSettings(
          appointmentItemHeight: 100,
          monthHeaderSettings: MonthHeaderSettings(
            monthFormat: 'MMMM, yyyy',
            height: 70,
            textAlign: TextAlign.left,
            backgroundColor: context.theme.bg,
            monthTextStyle: TextStyle(
              color: context.theme.textColor,
              fontSize: 20,
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
              fontSize: 16,
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
              backgroundColor: Colors.transparent,
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
              // Defensive check: prevent rendering with invalid constraints
              if (constraints.maxHeight <= 0 || constraints.maxWidth <= 0) {
                return const SizedBox.shrink();
              }

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
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context, AppointmentData appointment) {
    final color = _getStatusColor(context, appointment.status);
    final bg = color.withOpacity(0.08); // Softer background

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent strip
              Container(width: 6, color: color),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Time Column
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${appointment.appointmentStartTime.hour}:${appointment.appointmentStartTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: context.theme.textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${appointment.appointmentEndTime.hour}:${appointment.appointmentEndTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: context.theme.mutedForeground,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Divider
                      Container(
                        width: 1,
                        height: 40,
                        color: context.theme.border,
                      ),
                      const SizedBox(width: 20),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              appointment.patient.fullName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: context.theme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 14,
                                  color: context.theme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    appointment.doctor.name ?? 'Unknown Doctor',
                                    style: TextStyle(
                                      color: context.theme.mutedForeground,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          _getStatusText(appointment.status),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
    final style = _getAppointmentStyle(appointment.status);
    final isSmall = constraints.maxHeight < 40;

    return Container(
      decoration: BoxDecoration(
        color: style.bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: style.borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: isSmall
          ? Center(
              child: Text(
                appointment.patient.fullName,
                style: TextStyle(
                  color: style.textColor,
                  fontSize: 10,
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
                    color: style.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (view != CalendarView.month)
                  Text(
                    'Dr. ${appointment.doctor.name ?? ''}',
                    style: TextStyle(
                      color: style.textColor.withOpacity(0.8),
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
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
    final style = _getAppointmentStyle(appointment.status);
    return Container(
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: style.textColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            appointment.patient.fullName,
            style: TextStyle(
              color: context.theme.textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
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
    final style = _getAppointmentStyle(appointment.status);
    return Container(
      decoration: BoxDecoration(
        color: style.bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: style.textColor, width: 4)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            appointment.patient.fullName,
            style: TextStyle(
              color: style.textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    return _getAppointmentStyle(status).textColor;
  }

  _AppointmentStyle _getAppointmentStyle(String status) {
    switch (status) {
      case 'BOOKED':
      case 'RESCHEDULED':
        return _AppointmentStyle(
          bgColor: const Color(0xFFEFF6FF), // blue-50
          textColor: const Color(0xFF1D4ED8), // blue-700
          borderColor: const Color(0xFFBFDBFE), // blue-200
        );
      case 'CONFIRMED':
        return _AppointmentStyle(
          bgColor: const Color(0xFFF0FDF4), // green-50
          textColor: const Color(0xFF15803D), // green-700
          borderColor: const Color(0xFFBBF7D0), // green-200
        );
      case 'COMPLETED':
        return _AppointmentStyle(
          bgColor: const Color(
            0xFFF5F5F5,
          ), // neutral-100 (slightly darker than 50 for visibility)
          textColor: const Color(0xFF404040), // neutral-700
          borderColor: const Color(0xFFE5E5E5), // neutral-200
        );
      case 'CANCELLED':
      case 'CANCELLED_BY_STAFF':
      case 'CANCELLED_BY_PATIENT':
        return _AppointmentStyle(
          bgColor: const Color(0xFFFEF2F2), // red-50
          textColor: const Color(0xFFB91C1C), // red-700
          borderColor: const Color(0xFFFECACA), // red-200
        );
      case 'NO_SHOW':
        return _AppointmentStyle(
          bgColor: const Color(0xFFFFF7ED), // orange-50
          textColor: const Color(0xFFC2410C), // orange-700
          borderColor: const Color(0xFFFED7AA), // orange-200
        );
      default:
        return _AppointmentStyle(
          bgColor: const Color(0xFFFAFAFA),
          textColor: const Color(0xFF171717),
          borderColor: const Color(0xFFE5E5E5),
        );
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'BOOKED':
        return 'Booked';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
      case 'CANCELLED_BY_STAFF':
      case 'CANCELLED_BY_PATIENT':
        return 'Cancelled';
      case 'RESCHEDULED':
        return 'Rescheduled';
      case 'NO_SHOW':
        return 'No Show';
      default:
        return status;
    }
  }
}

class _AppointmentStyle {
  final Color bgColor;
  final Color textColor;
  final Color borderColor;

  _AppointmentStyle({
    required this.bgColor,
    required this.textColor,
    required this.borderColor,
  });
}
