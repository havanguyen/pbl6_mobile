import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/dto/appointment_dto.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';
import 'package:pbl6mobile/model/services/remote/doctor_service.dart';
import 'package:pbl6mobile/model/services/remote/patient_service.dart';
import 'package:pbl6mobile/model/services/remote/specialty_service.dart';
import 'package:pbl6mobile/model/services/remote/work_location_service.dart';

class CreateAppointmentVm extends ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();
  final PatientService _patientService = PatientService();

  // --- State Variables ---
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;

  // Step 1: Patient
  Patient? _selectedPatient;
  List<Patient> _patients = [];
  bool _isLoadingPatients = false;

  // Step 2: Location & Specialty (Independent)
  WorkLocation? _selectedLocation;
  Specialty? _selectedSpecialty;

  // Step 3: Doctor (Dependent on Location & Specialty)
  Doctor? _selectedDoctor;

  // Step 4: Date & Time (Dependent on Doctor & Location)
  DateTime? _selectedDate;
  List<String> _availableDates = [];
  bool _isLoadingDates = false;
  List<DoctorSlot> _slots = [];
  DoctorSlot? _selectedSlot;
  bool _isLoadingSlots = false;

  // Step 5: Details
  String _reason = '';
  String _notes = '';
  double? _priceAmount;
  String _currency = 'VND';
  String? _eventId; // From hold slot

  // --- Getters ---
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Patient? get selectedPatient => _selectedPatient;
  List<Patient> get patients => _patients;
  bool get isLoadingPatients => _isLoadingPatients;

  WorkLocation? get selectedLocation => _selectedLocation;
  Specialty? get selectedSpecialty => _selectedSpecialty;

  Doctor? get selectedDoctor => _selectedDoctor;

  DateTime? get selectedDate => _selectedDate;
  List<String> get availableDates => _availableDates;
  bool get isLoadingDates => _isLoadingDates;
  List<DoctorSlot> get slots => _slots;
  DoctorSlot? get selectedSlot => _selectedSlot;
  bool get isLoadingSlots => _isLoadingSlots;

  String get reason => _reason;
  String get notes => _notes;
  double? get priceAmount => _priceAmount;
  String get currency => _currency;

  // --- Actions ---

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  Future<void> init() async {
    await Future.wait([_fetchLocations(), _fetchSpecialties()]);
  }

  // Step 1: Patient Search
  Future<void> searchPatients(String query) async {
    _isLoadingPatients = true;
    notifyListeners();

    try {
      final result = await _patientService.getPatients(
        search: query.isEmpty ? null : query,
        limit: 20,
      );
      _patients = result['patients'] as List<Patient>;
    } catch (e) {
      print('Search patients error: $e');
      _patients = [];
    }

    _isLoadingPatients = false;
    notifyListeners();
  }

  void selectPatient(Patient? patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

  // Step 2: Location & Specialty (Independent)
  List<WorkLocation> _locations = [];
  List<Specialty> _allSpecialties = [];

  List<WorkLocation> get locations => _locations;
  List<Specialty> get allSpecialties => _allSpecialties;

  Future<void> _fetchLocations() async {
    try {
      final result = await LocationWorkService.getAllLocations(
        limit: 100,
        sortBy: 'name',
        sortOrder: 'asc',
      );
      // LocationWorkService returns Map<String, dynamic>
      if (result['data'] != null) {
        _locations = (result['data'] as List)
            .map((e) => WorkLocation.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _locations = [];
      }
    } catch (e) {
      print('Fetch locations error: $e');
      _locations = [];
    }
    notifyListeners();
  }

  Future<void> _fetchSpecialties() async {
    try {
      final result = await SpecialtyService.getAllSpecialties(
        limit: 100,
        sortBy: 'name',
        sortOrder: 'asc',
      );
      if (result.success) {
        _allSpecialties = result.data;
      } else {
        _allSpecialties = [];
      }
    } catch (e) {
      print('Fetch specialties error: $e');
      _allSpecialties = [];
    }
    notifyListeners();
  }

  void selectLocation(WorkLocation? location) {
    print('--- [DEBUG] selectLocation: ${location?.name} ---');
    if (_selectedLocation != location) {
      _selectedLocation = location;
      _resetDoctor();
      _fetchDoctors(); // Fetch doctors if both location and specialty are selected
    }
    notifyListeners();
  }

  void selectSpecialty(Specialty? specialty) {
    print('--- [DEBUG] selectSpecialty: ${specialty?.name} ---');
    if (_selectedSpecialty != specialty) {
      _selectedSpecialty = specialty;
      _resetDoctor();
      _fetchDoctors(); // Fetch doctors if both location and specialty are selected
    }
    notifyListeners();
  }

  void _resetDoctor() {
    _selectedDoctor = null;
    _doctors = []; // Clear doctors list
    _resetDateAndTime();
  }

  // Step 3: Doctor (Dependent on Location & Specialty)
  List<Doctor> _doctors = [];
  bool _isLoadingDoctors = false;
  List<Doctor> get doctors => _doctors;
  bool get isLoadingDoctors => _isLoadingDoctors;

  Future<void> _fetchDoctors() async {
    if (_selectedLocation == null || _selectedSpecialty == null) {
      _doctors = [];
      notifyListeners();
      return;
    }

    _isLoadingDoctors = true;
    notifyListeners();

    try {
      final result = await DoctorService.getDoctors(
        limit: 100,
        specialtyId: _selectedSpecialty!.id,
        workLocationId: _selectedLocation!.id,
      );
      if (result.success) {
        _doctors = result.data;
      } else {
        _doctors = [];
      }
    } catch (e) {
      print('Fetch doctors error: $e');
      _doctors = [];
    }

    _isLoadingDoctors = false;
    notifyListeners();
  }

  void selectDoctor(Doctor? doctor) {
    print('--- [DEBUG] selectDoctor: ${doctor?.fullName} ---');
    if (_selectedDoctor != doctor) {
      _selectedDoctor = doctor;
      _resetDateAndTime();
      if (doctor != null) {
        fetchAvailableDates();
      }
    }
    notifyListeners();
  }

  void _resetDateAndTime() {
    _selectedDate = null;
    _availableDates = [];
    _slots = [];
    _selectedSlot = null;
  }

  // Step 4: Date & Time
  Future<void> fetchAvailableDates() async {
    if (_selectedDoctor == null || _selectedLocation == null) return;

    _isLoadingDates = true;
    _availableDates = []; // Clear old dates
    notifyListeners();

    try {
      _availableDates = await DoctorService.getDoctorAvailableDates(
        _selectedDoctor!.id,
        _selectedLocation!.id,
      );
    } catch (e) {
      print('Fetch available dates error: $e');
    }

    _isLoadingDates = false;
    notifyListeners();
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    _selectedSlot = null;
    _slots = [];
    await fetchSlots();
  }

  Future<void> fetchSlots() async {
    if (_selectedDoctor == null ||
        _selectedLocation == null ||
        _selectedDate == null)
      return;

    _isLoadingSlots = true;
    notifyListeners();

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      _slots = await DoctorService.getDoctorAvailableSlots(
        _selectedDoctor!.id,
        _selectedLocation!.id,
        dateStr,
        allowPast:
            true, // Allow booking for today even if slightly past? Or strictly future?
      );
    } catch (e) {
      print('Fetch slots error: $e');
      _slots = [];
    }

    _isLoadingSlots = false;
    notifyListeners();
  }

  void selectSlot(DoctorSlot slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  // Step 5: Details & Booking
  void setReason(String val) {
    _reason = val;
    notifyListeners();
  }

  void setNotes(String val) {
    _notes = val;
    notifyListeners();
  }

  void setPrice(String val) {
    _priceAmount = double.tryParse(val);
    notifyListeners();
  }

  void setCurrency(String val) {
    _currency = val;
    notifyListeners();
  }

  Future<bool> holdSlot() async {
    if (_selectedDoctor == null ||
        _selectedSlot == null ||
        _selectedLocation == null ||
        _selectedDate == null) {
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final req = HoldAppointmentRequest(
        doctorId: _selectedDoctor!.id,
        locationId: _selectedLocation!.id,
        serviceDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        timeStart: _selectedSlot!.timeStart,
        timeEnd: _selectedSlot!.timeEnd,
      );

      final id = await _appointmentService.holdSlot(req);

      _isLoading = false;
      if (id != null) {
        _eventId = id;
        notifyListeners();
        return true;
      } else {
        _error = "Không thể giữ chỗ. Vui lòng thử lại.";
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmBooking() async {
    if (_selectedPatient == null || _selectedSpecialty == null) {
      _error = "Thiếu thông tin bắt buộc";
      notifyListeners();
      return false;
    }

    // Must hold slot first if not already held (though flow usually enforces it)
    if (_eventId == null) {
      final held = await holdSlot();
      if (!held) return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final req = CreateAppointmentRequest(
        eventId: _eventId,
        patientId: _selectedPatient!.id,
        specialtyId: _selectedSpecialty!.id,
        reason: _reason,
        notes: _notes,
        priceAmount: _priceAmount,
        currency: _currency,
        doctorId: _selectedDoctor?.id,
        locationId: _selectedLocation?.id,
        serviceDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        timeStart: _selectedSlot?.timeStart,
        timeEnd: _selectedSlot?.timeEnd,
      );

      final success = await _appointmentService.createAppointment(req);

      _isLoading = false;
      if (!success) {
        _error = "Đặt lịch thất bại. Vui lòng thử lại.";
      }
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
