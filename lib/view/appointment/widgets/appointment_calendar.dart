import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final theme = Theme.of(context);

    return SfCalendar(
      controller: controller,
      view: currentView,
      dataSource: vm.dataSource,
      onViewChanged: onViewChanged,
      initialSelectedDate: DateTime.now(),
      initialDisplayDate: DateTime.now(),
      appointmentBuilder: (context, details) =>
          _appointmentBuilder(context, details, vm),
      timeSlotViewSettings: const TimeSlotViewSettings(
        startHour: 7,
        endHour: 18,
        nonWorkingDays: <int>[DateTime.saturday, DateTime.sunday],
        timeIntervalHeight: 60,
      ),
      monthViewSettings: const MonthViewSettings(
        appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
        showAgenda: true,
      ),
      scheduleViewSettings: ScheduleViewSettings(
        appointmentItemHeight: 90,
        monthHeaderSettings: MonthHeaderSettings(
          height: 100,
          textAlign: TextAlign.left,
          backgroundColor: theme.primaryColor.withOpacity(0.1),
          monthFormat: 'MMMM, yyyy',
          monthTextStyle: TextStyle(
            color: theme.textTheme.titleLarge?.color ?? theme.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: (calendarTapDetails) {
        if (calendarTapDetails.targetElement == CalendarElement.appointment) {
          final dynamic appointment = calendarTapDetails.appointments?.first;
          if (appointment is AppointmentData) {
            _showAppointmentDetails(context, appointment);
          }
        }
      },
    );
  }

  void _showAppointmentDetails(BuildContext context, AppointmentData app) {
    final vm = context.read<AppointmentVm>();
    final color =
        vm.dataSource?.getColor(vm.dataSource!.appointments!.indexOf(app)) ??
        Colors.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AppointmentDetailsSheet(appointment: app, highlightColor: color);
      },
    );
  }

  Widget _appointmentBuilder(
    BuildContext context,
    CalendarAppointmentDetails details,
    AppointmentVm vm,
  ) {
    final appointment = details.appointments.first as AppointmentData;
    final color =
        vm.dataSource?.getColor(
          vm.dataSource!.appointments!.indexOf(appointment),
        ) ??
        Colors.blue;

    final bool isDarkBackground = color.computeLuminance() < 0.5;
    final Color mainTextColor = isDarkBackground
        ? Colors.white
        : Colors.black87;
    final Color secondaryTextColor = isDarkBackground
        ? Colors.white70
        : Colors.black54;

    final DateFormat timeFormatter = DateFormat('HH:mm');
    final String startTime = timeFormatter.format(
      appointment.appointmentStartTime,
    );
    final String patientName = appointment.patient.fullName;
    final String doctorName = appointment.doctor.name ?? 'N/A';

    if (currentView == CalendarView.day ||
        currentView == CalendarView.timelineDay) {
      return Container(
        width: details.bounds.width,
        height: details.bounds.height,
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: mainTextColor, size: 12),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '$startTime - $patientName',
                    style: TextStyle(
                      color: mainTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: mainTextColor,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    doctorName,
                    style: TextStyle(color: mainTextColor, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            if (appointment.reason != null && appointment.reason!.isNotEmpty)
              Row(
                children: [
                  Icon(
                    Icons.subject_outlined,
                    color: secondaryTextColor,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      appointment.reason!,
                      style: TextStyle(color: secondaryTextColor, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    if (currentView == CalendarView.week) {
      return Container(
        width: details.bounds.width,
        height: details.bounds.height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: mainTextColor, size: 10),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    '$startTime $patientName',
                    style: TextStyle(color: mainTextColor, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.medical_services_outlined,
                  color: secondaryTextColor,
                  size: 10,
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    doctorName,
                    style: TextStyle(color: secondaryTextColor, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (currentView == CalendarView.month) {
      return Container(
        width: details.bounds.width,
        height: details.bounds.height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          '$startTime - $patientName',
          style: TextStyle(color: mainTextColor, fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }

    if (currentView == CalendarView.schedule) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 5,
              height: 70,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildScheduleRow(
                    context,
                    Icons.person_outline,
                    patientName,
                    mainTextColor: Theme.of(
                      context,
                    ).textTheme.titleMedium?.color,
                    isBold: true,
                  ),
                  _buildScheduleRow(
                    context,
                    Icons.medical_services_outlined,
                    doctorName,
                    mainTextColor: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color,
                  ),
                  _buildScheduleRow(
                    context,
                    Icons.subject_outlined,
                    appointment.reason ?? 'Không có',
                    mainTextColor: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: details.bounds.width,
      height: details.bounds.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4.0),
      child: Text(
        '$startTime $patientName',
        style: TextStyle(color: mainTextColor, fontSize: 10),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Widget _buildScheduleRow(
    BuildContext context,
    IconData icon,
    String text, {
    Color? mainTextColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: mainTextColor ?? Theme.of(context).textTheme.bodyMedium?.color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color:
                  mainTextColor ??
                  Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}
