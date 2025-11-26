import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/dto/appointment_dto.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/model/services/remote/appointment_service.dart';

class CreateAppointmentVm extends ChangeNotifier {
  final AppointmentService _service = AppointmentService();

  int _currentStep = 0;
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Specialty? _selectedSpecialty;
  WorkLocation? _selectedLocation;
  Doctor? _selectedDoctor;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  Specialty? get selectedSpecialty => _selectedSpecialty;
  WorkLocation? get selectedLocation => _selectedLocation;
  Doctor? get selectedDoctor => _selectedDoctor;
  DateTime get selectedDate => _selectedDate;

  List<DoctorSlot> _slots = [];
  DoctorSlot? _selectedSlot;
  List<DoctorSlot> get slots => _slots;
  DoctorSlot? get selectedSlot => _selectedSlot;
  String? _eventId;

  Patient? _selectedPatient;
  Patient? get selectedPatient => _selectedPatient;

  String _reason = '';
  String _notes = '';
  double? _priceAmount;
  String _currency = 'VND';

  String get reason => _reason;
  String get notes => _notes;
  double? get priceAmount => _priceAmount;
  String get currency => _currency;

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void setInitData({Specialty? specialty, WorkLocation? location, Doctor? doctor}) {
    if (specialty != null) _selectedSpecialty = specialty;
    if (location != null) _selectedLocation = location;
    if (doctor != null) _selectedDoctor = doctor;

    _selectedSlot = null;
    _slots = [];
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = date;
    _selectedSlot = null;
    _slots = [];
    notifyListeners();
  }

  Future<void> fetchSlots() async {
    if (_selectedDoctor == null || _selectedLocation == null) return;

    _isLoading = true;
    notifyListeners();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final result = await _service.getDoctorSlots(
      doctorId: _selectedDoctor!.id,
      date: dateStr,
      locationId: _selectedLocation!.id,
    );

    if (result != null) {
      _slots = result;
    } else {
      _slots = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectSlot(DoctorSlot slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  Future<bool> holdSlot() async {
    if (_selectedDoctor == null || _selectedSlot == null || _selectedLocation == null) return false;

    _isLoading = true;
    notifyListeners();

    final req = HoldAppointmentRequest(
      doctorId: _selectedDoctor!.id,
      locationId: _selectedLocation!.id,
      serviceDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      timeStart: _selectedSlot!.timeStart,
      timeEnd: _selectedSlot!.timeEnd,
    );

    final id = await _service.holdSlot(req);

    _isLoading = false;
    if (id != null) {
      _eventId = id;
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  void setPatient(Patient patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

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

  Future<bool> confirmBooking() async {
    if (_selectedPatient == null || _selectedSpecialty == null) return false;

    _isLoading = true;
    notifyListeners();

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
      serviceDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
      timeStart: _selectedSlot?.timeStart,
      timeEnd: _selectedSlot?.timeEnd,
    );

    final success = await _service.createAppointment(req);

    _isLoading = false;
    notifyListeners();
    return success;
  }
}