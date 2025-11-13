import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/appointment_data.dart';
import 'package:pbl6mobile/view_model/appointment/appointment_vm.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

class ListAppointmentPage extends StatefulWidget {
  const ListAppointmentPage({super.key});

  @override
  State<ListAppointmentPage> createState() => _ListAppointmentPageState();
}

class _ListAppointmentPageState extends State<ListAppointmentPage>
    with SingleTickerProviderStateMixin {
  final CalendarController _controller = CalendarController();
  TabController? _tabController;

  CalendarView _currentView = CalendarView.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    _tabController!.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDataForVisibleDates(details: null);
    });
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController == null || _tabController!.indexIsChanging) {
      return;
    }

    final newView = _getViewFromIndex(_tabController!.index);
    if (_currentView == newView) {
      return;
    }

    setState(() {
      _currentView = newView;
    });
    _controller.view = _currentView;

    _fetchDataForVisibleDates(details: null);
  }

  CalendarView _getViewFromIndex(int index) {
    switch (index) {
      case 0:
        return CalendarView.day;
      case 1:
        return CalendarView.week;
      case 2:
        return CalendarView.timelineDay;
      case 3:
        return CalendarView.month;
      case 4:
        return CalendarView.schedule;
      default:
        return CalendarView.week;
    }
  }

  void _fetchDataForVisibleDates({required ViewChangedDetails? details}) {
    final vm = context.read<AppointmentVm>();
    DateTime fromDate;
    DateTime toDate;

    final List<DateTime> visibleDates =
        details?.visibleDates ?? _getInitialVisibleDates(_currentView);

    if (_currentView == CalendarView.month) {
      final firstDay = visibleDates.firstWhere(
            (date) => date.day == 1,
        orElse: () => visibleDates.first,
      );
      fromDate = DateTime(firstDay.year, firstDay.month, 1);
      toDate = DateTime(firstDay.year, firstDay.month + 1, 0)
          .add(const Duration(days: 1));
    } else {
      fromDate = visibleDates.first;
      toDate = visibleDates.last.add(const Duration(days: 1));
    }

    vm.fetchAppointments(fromDate, toDate);
  }

  List<DateTime> _getInitialVisibleDates(CalendarView view) {
    final DateTime now = DateTime.now();
    if (view == CalendarView.month) {
      return [DateTime(now.year, now.month, 1)];
    } else if (view == CalendarView.day || view == CalendarView.timelineDay) {
      return [now];
    } else if (view == CalendarView.schedule) {
      return [now, now.add(const Duration(days: 30))];
    } else {
      final int daysToMonday = now.weekday - DateTime.monday;
      final DateTime startOfWeek =
      now.subtract(Duration(days: daysToMonday < 0 ? 6 : daysToMonday));
      final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      return [startOfWeek, endOfWeek];
    }
  }

  void _onViewChanged(ViewChangedDetails details) {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      _fetchDataForVisibleDates(details: details);
    }
  }

  Widget _buildScheduleRow(BuildContext context, IconData icon, String text,
      {Color? mainTextColor, bool isBold = false}) {
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
              mainTextColor ?? Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _appointmentBuilder(
      BuildContext context, CalendarAppointmentDetails details) {
    final appointment = details.appointments.first as AppointmentData;
    final color = context.read<AppointmentVm>().dataSource?.getColor(
      context
          .read<AppointmentVm>()
          .dataSource!
          .appointments!
          .indexOf(appointment),
    ) ??
        Colors.blue;

    final bool isDarkBackground = color.computeLuminance() < 0.5;
    final Color mainTextColor = isDarkBackground ? Colors.white : Colors.black87;
    final Color secondaryTextColor =
    isDarkBackground ? Colors.white70 : Colors.black54;

    final DateFormat timeFormatter = DateFormat('HH:mm');
    final String startTime =
    timeFormatter.format(appointment.appointmentStartTime);
    final String patientName = appointment.patient.fullName;
    final String doctorName = appointment.doctor.name ?? 'N/A';

    if (_currentView == CalendarView.day ||
        _currentView == CalendarView.timelineDay) {
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
                Expanded(
                  child: Text(
                    '$startTime - $patientName',
                    style: TextStyle(
                      color: mainTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.medical_services_outlined,
                    color: mainTextColor, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    doctorName,
                    style: TextStyle(color: mainTextColor, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (appointment.reason != null && appointment.reason!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.subject_outlined,
                      color: secondaryTextColor, size: 10),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment.reason!,
                      style: TextStyle(color: secondaryTextColor, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    }

    if (_currentView == CalendarView.week) {
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
                Icon(Icons.medical_services_outlined,
                    color: secondaryTextColor, size: 10),
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

    if (_currentView == CalendarView.month) {
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

    if (_currentView == CalendarView.schedule) {
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScheduleRow(
                    context,
                    Icons.person_outline,
                    patientName,
                    mainTextColor:
                    Theme.of(context).textTheme.titleMedium?.color,
                    isBold: true,
                  ),
                  const SizedBox(height: 4),
                  _buildScheduleRow(
                    context,
                    Icons.medical_services_outlined,
                    doctorName,
                    mainTextColor:
                    Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 4),
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
        overflow: TextOverflow.clip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppointmentVm>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Lịch khám'),
        actions: [
          if (vm.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.indicatorColor,
          labelColor: theme.primaryTextTheme.titleLarge?.color ?? Colors.white,
          unselectedLabelColor:
          (theme.primaryTextTheme.titleLarge?.color ?? Colors.white)
              .withOpacity(0.7),
          tabs: const [
            Tab(text: 'Ngày'),
            Tab(text: 'Tuần'),
            Tab(text: 'Timeline'),
            Tab(text: 'Tháng'),
            Tab(text: 'Lịch trình'),
          ],
        ),
      ),
      body: SfCalendar(
        controller: _controller,
        view: _currentView,
        dataSource: vm.dataSource,
        onViewChanged: _onViewChanged,
        initialSelectedDate: DateTime.now(),
        initialDisplayDate: DateTime.now(),
        appointmentBuilder: _appointmentBuilder,
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
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, AppointmentData app) {
    final DateFormat timeFormatter = DateFormat('HH:mm');
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);
    final color = context.read<AppointmentVm>().dataSource?.getColor(
      context
          .read<AppointmentVm>()
          .dataSource!
          .appointments!
          .indexOf(app),
    ) ??
        Colors.blue;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BN: ${app.patient.fullName}',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(height: 16),
              _buildDetailRow(
                Icons.person_outline,
                'Bác sĩ:',
                app.doctor.name ?? 'N/A',
              ),
              _buildDetailRow(
                Icons.bookmark_border,
                'Trạng thái:',
                app.status,
                highlightColor: color,
              ),
              _buildDetailRow(
                Icons.calendar_today_outlined,
                'Ngày:',
                dateFormatter.format(app.appointmentStartTime),
              ),
              _buildDetailRow(
                Icons.access_time_outlined,
                'Giờ:',
                '${timeFormatter.format(app.appointmentStartTime)} - ${timeFormatter.format(app.appointmentEndTime)}',
              ),
              const SizedBox(height: 8),
              Text(
                'Lý do khám:',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(app.reason ?? 'Không có'),
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
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value,
      {Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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