import 'package:flutter/material.dart';
import 'package:pbl6mobile/view/appointment/widgets/appointment_filter_dialog.dart';
import 'package:pbl6mobile/view_model/appointment/appointment_vm.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:pbl6mobile/view/appointment/create_appointment_page.dart';
import 'package:pbl6mobile/view/appointment/widgets/appointment_calendar.dart';
import 'package:pbl6mobile/view/appointment/widgets/custom_calendar_header.dart';
import 'package:pbl6mobile/view/appointment/widgets/calendar_settings_dialog.dart';

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

  String? _selectedDoctorId;
  String? _selectedWorkLocationId;
  String? _selectedSpecialtyId;

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

    final currentDate = _controller.displayDate;
    setState(() {
      _currentView = newView;
    });
    _controller.view = _currentView;

    // Restore date if needed
    if (currentDate != null) {
      _controller.displayDate = currentDate;
    }

    // Force fetch data after view update to ensure consistency
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchDataForVisibleDates(details: null);
      }
    });
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

    if (visibleDates.isEmpty) return;

    if (_currentView == CalendarView.month) {
      final firstDay = visibleDates.firstWhere(
        (date) => date.day == 1,
        orElse: () => visibleDates.first,
      );
      fromDate = DateTime(firstDay.year, firstDay.month, 1);
      toDate = DateTime(
        firstDay.year,
        firstDay.month + 1,
        0,
      ).add(const Duration(days: 1));
    } else if (_currentView == CalendarView.schedule) {
      // For schedule view, fetch a wider range as it scrolls continuously
      fromDate = visibleDates.first;
      toDate = visibleDates.last.add(const Duration(days: 30));
    } else {
      // Expand range to ensure we catch appointments near the edges or if view changes slightly
      fromDate = visibleDates.first.subtract(const Duration(days: 7));
      toDate = visibleDates.last.add(const Duration(days: 7));
    }

    print('--- [DEBUG] ListAppointmentPage._fetchDataForVisibleDates ---');
    print('Current View: $_currentView');
    print('Visible Dates: ${visibleDates.first} to ${visibleDates.last}');
    print('Fetching Range: $fromDate to $toDate');

    vm.fetchAppointments(
      fromDate,
      toDate,
      doctorId: _selectedDoctorId,
      workLocationId: _selectedWorkLocationId,
      specialtyId: _selectedSpecialtyId,
    );
  }

  List<DateTime> _getInitialVisibleDates(CalendarView view) {
    final DateTime anchorDate = _controller.displayDate ?? DateTime.now();
    if (view == CalendarView.month) {
      return [DateTime(anchorDate.year, anchorDate.month, 1)];
    } else if (view == CalendarView.day || view == CalendarView.timelineDay) {
      return [anchorDate];
    } else if (view == CalendarView.schedule) {
      return [anchorDate, anchorDate.add(const Duration(days: 30))];
    } else {
      final int daysToMonday = anchorDate.weekday - DateTime.monday;
      final DateTime startOfWeek = anchorDate.subtract(
        Duration(days: daysToMonday < 0 ? 6 : daysToMonday),
      );
      final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
      return [startOfWeek, endOfWeek];
    }
  }

  void _onViewChanged(ViewChangedDetails details) {
    if (_tabController != null && !_tabController!.indexIsChanging) {
      _fetchDataForVisibleDates(details: details);
    }
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => AppointmentFilterDialog(
        selectedDoctorId: _selectedDoctorId,
        selectedWorkLocationId: _selectedWorkLocationId,
        selectedSpecialtyId: _selectedSpecialtyId,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedDoctorId = result['doctorId'];
        _selectedWorkLocationId = result['workLocationId'];
        _selectedSpecialtyId = result['specialtyId'];
      });
      _fetchDataForVisibleDates(details: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppointmentVm>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchDataForVisibleDates(details: null);
          },
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Appointments',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (vm.isLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 16),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            _fetchDataForVisibleDates(details: null);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color:
                                (_selectedDoctorId != null ||
                                    _selectedWorkLocationId != null ||
                                    _selectedSpecialtyId != null)
                                ? theme.primaryColor
                                : null,
                          ),
                          onPressed: _showFilterDialog,
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  const CalendarSettingsDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CustomCalendarHeader(
                controller: _controller,
                currentView: _currentView,
                onTodayTap: () {
                  _controller.displayDate = DateTime.now();
                },
                onViewChanged: (view) {
                  setState(() {
                    _currentView = view;
                  });
                  _controller.view = view;
                  // Fetch data will be triggered by onViewChanged callback of SfCalendar
                },
                onAddTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateAppointmentPage(),
                    ),
                  ).then((_) {
                    _fetchDataForVisibleDates(details: null);
                  });
                },
              ),
              Expanded(
                child: AppointmentCalendar(
                  controller: _controller,
                  currentView: _currentView,
                  onViewChanged: _onViewChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
