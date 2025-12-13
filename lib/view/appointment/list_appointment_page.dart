import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view/appointment/widgets/appointment_filter_dialog.dart';
import 'package:pbl6mobile/view_model/appointment/appointment_vm.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:pbl6mobile/view/appointment/create_appointment_page.dart';
import 'package:pbl6mobile/view/appointment/widgets/appointment_calendar.dart';
import 'package:pbl6mobile/view/appointment/widgets/custom_calendar_header.dart';
import 'package:pbl6mobile/view/appointment/widgets/calendar_settings_dialog.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/shared/services/store.dart';

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
  bool _isDoctor = false;
  late AppointmentVm _vm;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);
    _tabController!.addListener(_onTabChanged);

    _vm = context.read<AppointmentVm>();
    _vm.addListener(_onErrorChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });
  }

  void _onErrorChanged() {
    if (!mounted) return;
    if (_vm.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.error!),
          backgroundColor: context.theme.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // We don't clear error here as it might be needed for UI state (e.g. empty view)
      // modifying it would trigger another notifyListeners loop
    }
  }

  Future<void> _initializePage() async {
    final role = await Store.getUserRole();

    if (role?.toUpperCase() == 'DOCTOR') {
      setState(() {
        _isDoctor = true;
      });
    }

    _fetchDataForVisibleDates(details: null, forceRefresh: true);
  }

  @override
  void dispose() {
    _vm.removeListener(_onErrorChanged);
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

  void _fetchDataForVisibleDates({
    required ViewChangedDetails? details,
    bool forceRefresh = false,
  }) {
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

    vm.fetchAppointments(
      fromDate,
      toDate,
      doctorId: _selectedDoctorId,
      forceRefresh: forceRefresh,
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
        isDoctor: _isDoctor,
      ),
    );

    if (result != null) {
      if (mounted) {
        setState(() {
          _selectedDoctorId = result['doctorId'];
        });
        _fetchDataForVisibleDates(details: null, forceRefresh: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppointmentVm>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            _fetchDataForVisibleDates(details: null, forceRefresh: true);
          },
          child: Column(
            children: [
              // Custom Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                color: context.theme.card,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: context.theme.textColor,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              ).translate('appointments_title'),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: context.theme.textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
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
                          icon: Icon(
                            Icons.refresh,
                            color: context.theme.textColor,
                          ),
                          onPressed: () {
                            _fetchDataForVisibleDates(
                              details: null,
                              forceRefresh: true,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.filter_list,
                            color: (_selectedDoctorId != null)
                                ? context.theme.primary
                                : context.theme.textColor,
                          ),
                          onPressed: _showFilterDialog,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: context.theme.textColor,
                          ),
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
                    _fetchDataForVisibleDates(
                      details: null,
                      forceRefresh: true,
                    );
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
