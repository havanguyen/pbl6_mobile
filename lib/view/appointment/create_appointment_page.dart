import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/model/entities/patient.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/view_model/appointment/create_appointment_vm.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/location_work_vm.dart';
import 'package:pbl6mobile/view_model/patient/patient_vm.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';

class CreateAppointmentPage extends StatelessWidget {
  const CreateAppointmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreateAppointmentVm(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Đặt lịch khám')),
        body: const _Body(),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpecialtyVm>().fetchSpecialties();
      context.read<LocationWorkVm>().fetchLocations();
      context.read<DoctorVm>().fetchDoctors();
      context.read<PatientVm>().loadPatients();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreateAppointmentVm>();

    return Stepper(
      type: StepperType.vertical,
      currentStep: vm.currentStep,
      onStepContinue: () async {
        await _handleStepContinue(context, vm);
      },
      onStepCancel: () {
        if (vm.currentStep > 0) {
          vm.setStep(vm.currentStep - 1);
        } else {
          Navigator.pop(context);
        }
      },
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            children: [
              if (vm.isLoading)
                const CircularProgressIndicator()
              else
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(vm.currentStep == 3 ? 'HOÀN TẤT' : 'TIẾP TỤC'),
                ),
              const SizedBox(width: 12),
              if (!vm.isLoading)
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('QUAY LẠI'),
                ),
            ],
          ),
        );
      },
      steps: [
        Step(
          title: const Text('Chọn thông tin khám'),
          content: _buildStep1(context),
          isActive: vm.currentStep >= 0,
          state: vm.currentStep > 0 ? StepState.complete : StepState.editing,
        ),
        Step(
          title: const Text('Chọn giờ khám'),
          content: _buildStep2(context),
          isActive: vm.currentStep >= 1,
          state: vm.currentStep > 1 ? StepState.complete : StepState.editing,
        ),
        Step(
          title: const Text('Thông tin bệnh nhân'),
          content: _buildStep3(context),
          isActive: vm.currentStep >= 2,
          state: vm.currentStep > 2 ? StepState.complete : StepState.editing,
        ),
        Step(
          title: const Text('Xác nhận & Chi tiết'),
          content: _buildStep4(context),
          isActive: vm.currentStep >= 3,
        ),
      ],
    );
  }

  Future<void> _handleStepContinue(BuildContext context, CreateAppointmentVm vm) async {
    if (vm.currentStep == 0) {
      if (vm.selectedDoctor == null || vm.selectedLocation == null || vm.selectedSpecialty == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn đầy đủ chuyên khoa, bác sĩ và địa điểm')));
        return;
      }
      await vm.fetchSlots();
      vm.setStep(1);
    } else if (vm.currentStep == 1) {
      if (vm.selectedSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn một khung giờ')));
        return;
      }
      final success = await vm.holdSlot();
      if (success) {
        vm.setStep(2);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể giữ chỗ lúc này, vui lòng thử lại')));
      }
    } else if (vm.currentStep == 2) {
      if (vm.selectedPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn bệnh nhân')));
        return;
      }
      vm.setStep(3);
    } else if (vm.currentStep == 3) {
      final success = await vm.confirmBooking();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt lịch thành công!')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Có lỗi xảy ra khi đặt lịch')));
      }
    }
  }

  Widget _buildStep1(BuildContext context) {
    final vm = context.watch<CreateAppointmentVm>();
    final specialtyVm = context.watch<SpecialtyVm>();
    final locationVm = context.watch<LocationWorkVm>();
    final doctorVm = context.watch<DoctorVm>();

    return Column(
      children: [
        DropdownButtonFormField<Specialty>(
          decoration: const InputDecoration(labelText: 'Chuyên khoa', border: OutlineInputBorder()),
          items: specialtyVm.specialties.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
          onChanged: (val) => vm.setInitData(specialty: val),
          value: vm.selectedSpecialty,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<WorkLocation>(
          decoration: const InputDecoration(labelText: 'Địa điểm', border: OutlineInputBorder()),
          items: locationVm.locations.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
          onChanged: (val) => vm.setInitData(location: val),
          value: vm.selectedLocation,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Doctor>(
          decoration: const InputDecoration(labelText: 'Bác sĩ', border: OutlineInputBorder()),
          items: doctorVm.doctors.map((e) => DropdownMenuItem(value: e, child: Text(e.fullName))).toList(),
          onChanged: (val) => vm.setInitData(doctor: val),
          value: vm.selectedDoctor,
        ),
        const SizedBox(height: 16),
        InputDatePickerFormField(
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 60)),
          initialDate: vm.selectedDate,
          onDateSubmitted: (date) => vm.setDate(date),
          fieldLabelText: 'Ngày khám',
        ),
      ],
    );
  }

  Widget _buildStep2(BuildContext context) {
    final vm = context.watch<CreateAppointmentVm>();

    if (vm.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    if (vm.slots.isEmpty) return const Text('Không có lịch trống cho ngày này', style: TextStyle(color: Colors.red));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Lịch khám ngày ${DateFormat('dd/MM/yyyy').format(vm.selectedDate)}:", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vm.slots.map((slot) {
            final isSelected = vm.selectedSlot == slot;
            return ChoiceChip(
              label: Text('${slot.timeStart} - ${slot.timeEnd}'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) vm.selectSlot(slot);
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    final vm = context.watch<CreateAppointmentVm>();
    final patientVm = context.watch<PatientVm>();

    return Column(
      children: [
        DropdownButtonFormField<Patient>(
          decoration: const InputDecoration(labelText: 'Chọn bệnh nhân có sẵn', border: OutlineInputBorder()),
          isExpanded: true,
          items: patientVm.patients.map((e) => DropdownMenuItem(value: e, child: Text('${e.fullName} (${e.phone ?? "N/A"})'))).toList(),
          onChanged: (val) {
            if (val != null) vm.setPatient(val);
          },
          value: vm.selectedPatient,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStep4(BuildContext context) {
    final vm = context.watch<CreateAppointmentVm>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Bác sĩ:', vm.selectedDoctor?.fullName ?? ""),
          _buildDetailRow('Chuyên khoa:', vm.selectedSpecialty?.name ?? ""),
          _buildDetailRow('Địa điểm:', vm.selectedLocation?.name ?? ""),
          const Divider(),
          _buildDetailRow('Bệnh nhân:', vm.selectedPatient?.fullName ?? ""),
          _buildDetailRow('SĐT:', vm.selectedPatient?.phone ?? ""),
          const Divider(),
          _buildDetailRow('Ngày:', DateFormat('dd/MM/yyyy').format(vm.selectedDate)),
          _buildDetailRow('Giờ:', '${vm.selectedSlot?.timeStart} - ${vm.selectedSlot?.timeEnd}', isBold: true, color: Colors.blue),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Lý do khám', border: OutlineInputBorder()),
            maxLines: 2,
            onChanged: (val) => vm.setReason(val),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Ghi chú thêm (Notes)', border: OutlineInputBorder()),
            maxLines: 2,
            onChanged: (val) => vm.setNotes(val),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'Giá tiền', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => vm.setPrice(val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Đơn vị', border: OutlineInputBorder()),
                  value: vm.currency,
                  items: ['VND', 'USD'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                    if (val != null) vm.setCurrency(val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}