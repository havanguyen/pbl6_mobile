
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pbl6mobile/model/entities/doctor_detail.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/model/entities/work_location.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view_model/location_work_management/location_work_vm.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/view_model/admin_management/doctor_management_vm.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EditDoctorProfilePage extends StatefulWidget {
  final DoctorDetail doctorDetail;

  const EditDoctorProfilePage({super.key, required this.doctorDetail});

  @override
  State<EditDoctorProfilePage> createState() => _EditDoctorProfilePageState();
}

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage> {
  final _formKey = GlobalKey<FormState>();
  // Text controllers
  late TextEditingController _degreeController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _portraitController;
  late TextEditingController _researchController;

  // Quill controller
  late quill.QuillController _introductionController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Dynamic list controllers
  late List<TextEditingController> _positionControllers;
  late List<TextEditingController> _membershipControllers;
  late List<TextEditingController> _awardControllers;
  late List<TextEditingController> _trainingControllers;
  late List<TextEditingController> _experienceControllers;

  // Multi-select values
  late List<Specialty> _selectedSpecialties;
  late List<WorkLocation> _selectedWorkLocations;

  @override
  void initState() {
    super.initState();
    // Fetch data for dropdowns
    context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
    context.read<LocationWorkVm>().fetchLocations();

    // Initialize controllers
    _degreeController = TextEditingController(text: widget.doctorDetail.degree ?? '');
    _avatarUrlController = TextEditingController(text: widget.doctorDetail.avatarUrl ?? '');
    _portraitController = TextEditingController(text: widget.doctorDetail.portrait ?? '');
    _researchController = TextEditingController(text: widget.doctorDetail.research ?? '');
    _initializeQuillController();
    _positionControllers = _initListControllers(widget.doctorDetail.position);
    _membershipControllers = _initListControllers(widget.doctorDetail.memberships);
    _awardControllers = _initListControllers(widget.doctorDetail.awards);
    _trainingControllers = _initListControllers(widget.doctorDetail.trainingProcess);
    _experienceControllers = _initListControllers(widget.doctorDetail.experience);
    _selectedSpecialties = List.from(widget.doctorDetail.specialties);
    _selectedWorkLocations = List.from(widget.doctorDetail.workLocations);
  }

  void _initializeQuillController() {
    final initialIntroduction = widget.doctorDetail.introduction;
    if (initialIntroduction != null && initialIntroduction.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(initialIntroduction));
        _introductionController = quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
      } catch (e) {
        final doc = quill.Document()..insert(0, initialIntroduction);
        _introductionController = quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
      }
    } else {
      _introductionController = quill.QuillController.basic();
    }
  }

  List<TextEditingController> _initListControllers(List<String>? items) {
    if (items == null || items.isEmpty) return [TextEditingController()];
    return items.map((item) => TextEditingController(text: item)).toList();
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _avatarUrlController.dispose();
    _portraitController.dispose();
    _researchController.dispose();
    _introductionController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _positionControllers.forEach((c) => c.dispose());
    _membershipControllers.forEach((c) => c.dispose());
    _awardControllers.forEach((c) => c.dispose());
    _trainingControllers.forEach((c) => c.dispose());
    _experienceControllers.forEach((c) => c.dispose());
    super.dispose();
  }

  List<String> _getValuesFromControllers(List<TextEditingController> controllers) {
    return controllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final introductionJson = jsonEncode(_introductionController.document.toDelta().toJson());

      final data = {
        'staffAccountId': widget.doctorDetail.id,
        'degree': _degreeController.text.trim(),
        'avatarUrl': _avatarUrlController.text.trim(),
        'portrait': _portraitController.text.trim(),
        'introduction': introductionJson,
        'research': _researchController.text.trim(),
        'position': _getValuesFromControllers(_positionControllers),
        'memberships': _getValuesFromControllers(_membershipControllers),
        'awards': _getValuesFromControllers(_awardControllers),
        'trainingProcess': _getValuesFromControllers(_trainingControllers),
        'experience': _getValuesFromControllers(_experienceControllers),
        'specialtyIds': _selectedSpecialties.map((e) => e.id).toList(),
        'locationIds': _selectedWorkLocations.map((e) => e.id).toList(),
      };

      final doctorVm = context.read<DoctorVm>();
      final future = widget.doctorDetail.profileId != null
          ? doctorVm.updateDoctorProfile(widget.doctorDetail.profileId!, data)
          : doctorVm.createDoctorProfile(data);

      future.then((success) {
        if (mounted) {
          if (success) {
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.doctorDetail.profileId != null ? 'Cập nhật' : 'Tạo'} hồ sơ thất bại')),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorDetail.profileId != null ? 'Chỉnh sửa hồ sơ' : 'Tạo hồ sơ'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile)],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(_degreeController, 'Học vị', Icons.school),
              _buildTextField(_avatarUrlController, 'URL Ảnh đại diện', Icons.image),
              _buildTextField(_portraitController, 'URL Ảnh chân dung', Icons.face),
              _buildQuillEditor(),
              _buildTextField(_researchController, 'Nghiên cứu khoa học', Icons.science, maxLines: 5),
              _buildDynamicListField('Chức vụ', _positionControllers),
              _buildDynamicListField('Thành viên hiệp hội', _membershipControllers),
              _buildDynamicListField('Giải thưởng', _awardControllers),
              _buildDynamicListField('Quá trình đào tạo', _trainingControllers),
              _buildDynamicListField('Kinh nghiệm', _experienceControllers),
              _buildMultiSelectSpecialties(),
              _buildMultiSelectLocations(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int? maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: context.theme.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildQuillEditor() {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giới thiệu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textColor),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: theme.border),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.input,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: quill.QuillSimpleToolbar(
                      controller: _introductionController,
                      config: const quill.QuillSimpleToolbarConfig(
                        toolbarSize: 20,
                        toolbarSectionSpacing: 2,
                        showAlignmentButtons: true,
                        showFontSize: false,
                        showDividers: false,
                        multiRowsDisplay: false,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Container(
                    height: 300,
                    color: theme.input,
                    padding: const EdgeInsets.all(5),
                    child: quill.QuillEditor(
                      controller: _introductionController,
                      focusNode: _focusNode,
                      scrollController: _scrollController,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicListField(String label, List<TextEditingController> controllers) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ...controllers.asMap().entries.map((entry) {
            int idx = entry.key;
            TextEditingController controller = entry.value;
            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(hintText: 'Mục ${idx + 1}'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () {
                    if (controllers.length > 1) {
                      setState(() => controllers.removeAt(idx));
                    }
                  },
                ),
              ],
            );
          }),
          TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Thêm mục'),
            onPressed: () => setState(() => controllers.add(TextEditingController())),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildMultiSelectSpecialties() {
    return Consumer<SpecialtyVm>(
      builder: (context, specialtyVm, child) {
        return _MultiSelectChipField<Specialty>(
          label: 'Chuyên khoa',
          allItems: specialtyVm.specialties,
          initialSelectedItems: _selectedSpecialties,
          itemName: (specialty) => specialty.name,
          onSelectionChanged: (selectedItems) {
            setState(() {
              _selectedSpecialties = selectedItems;
            });
          },
        );
      },
    );
  }

  Widget _buildMultiSelectLocations() {
    return Consumer<LocationWorkVm>(
      builder: (context, locationVm, child) {
        return _MultiSelectChipField<WorkLocation>(
          label: 'Nơi công tác',
          allItems: locationVm.locations,
          initialSelectedItems: _selectedWorkLocations,
          itemName: (location) => location.name,
          onSelectionChanged: (selectedItems) {
            setState(() {
              _selectedWorkLocations = selectedItems;
            });
          },
        );
      },
    );
  }
}

// Custom widget for multi-selection
class _MultiSelectChipField<T> extends StatefulWidget {
  final String label;
  final List<T> allItems;
  final List<T> initialSelectedItems;
  final String Function(T) itemName;
  final ValueChanged<List<T>> onSelectionChanged;

  const _MultiSelectChipField({
    required this.label,
    required this.allItems,
    required this.initialSelectedItems,
    required this.itemName,
    required this.onSelectionChanged,
  });

  @override
  _MultiSelectChipFieldState<T> createState() => _MultiSelectChipFieldState<T>();
}

class _MultiSelectChipFieldState<T> extends State<_MultiSelectChipField<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelectedItems);
  }

  void _showMultiSelect() async {
    final List<T>? results = await showDialog(
      context: context,
      builder: (BuildContext context) {
        final tempSelectedItems = List<T>.from(_selectedItems);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Chọn ${widget.label}'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: widget.allItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.allItems[index];
                    return CheckboxListTile(
                      title: Text(widget.itemName(item)),
                      value: tempSelectedItems.contains(item),
                      onChanged: (bool? selected) {
                        setState(() {
                          if (selected == true) {
                            tempSelectedItems.add(item);
                          } else {
                            tempSelectedItems.remove(item);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: const Text('Xong'),
                  onPressed: () => Navigator.of(context).pop(tempSelectedItems),
                ),
              ],
            );
          },
        );
      },
    );

    if (results != null) {
      setState(() {
        _selectedItems = results;
      });
      widget.onSelectionChanged(_selectedItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: context.theme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _selectedItems
                      .map((item) => Chip(
                    label: Text(widget.itemName(item)),
                    onDeleted: () {
                      setState(() {
                        _selectedItems.remove(item);
                      });
                      widget.onSelectionChanged(_selectedItems);
                    },
                  ))
                      .toList(),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text('Chọn ${widget.label}'),
                  onPressed: _showMultiSelect,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}