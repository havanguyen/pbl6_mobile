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

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controllers
  late TextEditingController _degreeController;
  late quill.QuillController _introductionController;
  late quill.QuillController _researchController;
  late List<String> _positions;
  late List<String> _memberships;
  late List<String> _awards;
  late List<String> _trainings;
  late List<String> _experiences;
  late List<Specialty> _selectedSpecialties;
  late List<WorkLocation> _selectedWorkLocations;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SpecialtyVm>().fetchSpecialties();
        context.read<LocationWorkVm>().fetchLocations();
      }
    });

    _degreeController =
        TextEditingController(text: widget.doctorDetail.degree ?? '');
    _introductionController =
        _initializeQuillController(widget.doctorDetail.introduction);
    _researchController =
        _initializeQuillController(widget.doctorDetail.research);
    _positions = List.from(widget.doctorDetail.position ?? []);
    _memberships = List.from(widget.doctorDetail.memberships ?? []);
    _awards = List.from(widget.doctorDetail.awards ?? []);
    _trainings = List.from(widget.doctorDetail.trainingProcess ?? []);
    _experiences = List.from(widget.doctorDetail.experience ?? []);
    _selectedSpecialties = List.from(widget.doctorDetail.specialties);
    _selectedWorkLocations = List.from(widget.doctorDetail.workLocations);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _degreeController.dispose();
    _introductionController.dispose();
    _researchController.dispose();
    super.dispose();
  }

  quill.QuillController _initializeQuillController(String? content) {
    if (content != null && content.isNotEmpty) {
      try {
        final doc = quill.Document.fromJson(jsonDecode(content));
        return quill.QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      } catch (e) {
        final doc = quill.Document()..insert(0, content);
        return quill.QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      }
    }
    return quill.QuillController.basic();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final introductionJson =
      jsonEncode(_introductionController.document.toDelta().toJson());
      final researchJson =
      jsonEncode(_researchController.document.toDelta().toJson());

      final bool isCreating = widget.doctorDetail.profileId == null;

      final Map<String, dynamic> data = {
        if (isCreating) 'staffAccountId': widget.doctorDetail.id,
        'degree': _degreeController.text.trim(),
        'introduction': introductionJson,
        'research': researchJson,
        'position': _positions,
        'memberships': _memberships,
        'awards': _awards,
        'trainingProcess': _trainings,
        'experience': _experiences,
        'specialtyIds': _selectedSpecialties.map((e) => e.id).toList(),
        'locationIds': _selectedWorkLocations.map((e) => e.id).toList(),
      };

      final doctorVm = context.read<DoctorVm>();
      final future = isCreating
          ? doctorVm.createDoctorProfile(data)
          : doctorVm.updateDoctorProfile(widget.doctorDetail.profileId!, data);

      future.then((success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${isCreating ? 'Tạo' : 'Cập nhật'} hồ sơ ${success ? 'thành công' : 'thất bại'}')),
          );
          if (success) {
            Navigator.pop(context, true);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<DoctorVm>().isOffline;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.doctorDetail.profileId != null
            ? 'Chỉnh sửa hồ sơ'
            : 'Tạo hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: isOffline ? null : _saveProfile,
            tooltip: isOffline ? 'Không thể lưu khi offline' : 'Lưu hồ sơ',
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cơ bản'),
            Tab(text: 'Kinh nghiệm'),
            Tab(text: 'Phân công'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(isOffline),
            _buildExperienceTab(isOffline),
            _buildAssignmentTab(isOffline),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab(bool isReadOnly) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField(_degreeController, 'Học vị', Icons.school,
              isReadOnly: isReadOnly),
          const SizedBox(height: 16),
          _QuillEditor(
            label: "Giới thiệu",
            controller: _introductionController,
            isReadOnly: isReadOnly,
          ),
          const SizedBox(height: 16),
          _QuillEditor(
            label: "Nghiên cứu khoa học",
            controller: _researchController,
            isReadOnly: isReadOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceTab(bool isReadOnly) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _DynamicListInput(
              label: 'Chức vụ',
              items: _positions,
              onChanged: (val) => setState(() => _positions = val),
              isReadOnly: isReadOnly),
          _DynamicListInput(
              label: 'Kinh nghiệm',
              items: _experiences,
              onChanged: (val) => setState(() => _experiences = val),
              isReadOnly: isReadOnly),
          _DynamicListInput(
              label: 'Quá trình đào tạo',
              items: _trainings,
              onChanged: (val) => setState(() => _trainings = val),
              isReadOnly: isReadOnly),
          _DynamicListInput(
              label: 'Giải thưởng',
              items: _awards,
              onChanged: (val) => setState(() => _awards = val),
              isReadOnly: isReadOnly),
          _DynamicListInput(
              label: 'Thành viên hiệp hội',
              items: _memberships,
              onChanged: (val) => setState(() => _memberships = val),
              isReadOnly: isReadOnly),
        ],
      ),
    );
  }

  Widget _buildAssignmentTab(bool isReadOnly) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMultiSelectSpecialties(isReadOnly),
          const SizedBox(height: 24),
          _buildMultiSelectLocations(isReadOnly),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isReadOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: isReadOnly,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: context.theme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: isReadOnly,
        fillColor: isReadOnly ? context.theme.input : null,
      ),
    );
  }

  Widget _buildMultiSelectSpecialties(bool isReadOnly) {
    return Consumer<SpecialtyVm>(
      builder: (context, specialtyVm, child) {
        return _MultiSelectChipField<Specialty>(
          label: 'Chuyên khoa',
          allItems: specialtyVm.specialties,
          initialSelectedItems: _selectedSpecialties,
          itemName: (specialty) => specialty.name,
          onSelectionChanged: (selectedItems) {
            setState(() => _selectedSpecialties = selectedItems);
          },
          isReadOnly: isReadOnly,
        );
      },
    );
  }

  Widget _buildMultiSelectLocations(bool isReadOnly) {
    return Consumer<LocationWorkVm>(
      builder: (context, locationVm, child) {
        return _MultiSelectChipField<WorkLocation>(
          label: 'Nơi công tác',
          allItems: locationVm.locations,
          initialSelectedItems: _selectedWorkLocations,
          itemName: (location) => location.name,
          onSelectionChanged: (selectedItems) {
            setState(() => _selectedWorkLocations = selectedItems);
          },
          isReadOnly: isReadOnly,
        );
      },
    );
  }
}
class _QuillEditor extends StatelessWidget {
  final String label;
  final quill.QuillController controller;
  final bool isReadOnly;

  const _QuillEditor({
    required this.label,
    required this.controller,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.border),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.theme.popover.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                if (!isReadOnly)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.input,
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: quill.QuillSimpleToolbar(
                      controller: controller,
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
                if (!isReadOnly) const Divider(height: 1),
                Container(
                  height: 300,
                  color: isReadOnly ? theme.input : theme.card,
                  padding: const EdgeInsets.all(5),
                  child: quill.QuillEditor.basic(
                    controller: controller,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DynamicListInput extends StatefulWidget {
  final String label;
  final List<String> items;
  final ValueChanged<List<String>> onChanged;
  final bool isReadOnly;

  const _DynamicListInput(
      {required this.label,
        required this.items,
        required this.onChanged,
        this.isReadOnly = false});

  @override
  __DynamicListInputState createState() => __DynamicListInputState();
}

class __DynamicListInputState extends State<_DynamicListInput> {
  final TextEditingController _textController = TextEditingController();

  void _addItem() {
    if (widget.isReadOnly) return;
    if (_textController.text.trim().isNotEmpty) {
      setState(() {
        widget.items.add(_textController.text.trim());
        widget.onChanged(widget.items);
        _textController.clear();
      });
    }
  }

  void _removeItem(int index) {
    if (widget.isReadOnly) return;
    setState(() {
      widget.items.removeAt(index);
      widget.onChanged(widget.items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (widget.items.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.theme.border)
            ),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: widget.items
                  .asMap()
                  .entries
                  .map((entry) => Chip(
                label: Text(entry.value),
                onDeleted:
                widget.isReadOnly ? null : () => _removeItem(entry.key),
              ))
                  .toList(),
            ),
          ),
        if (!widget.isReadOnly) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _textController,
            readOnly: widget.isReadOnly,
            decoration: InputDecoration(
              hintText: 'Thêm ${widget.label.toLowerCase()}...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addItem,
              ),
            ),
            onFieldSubmitted: (_) => _addItem(),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

// ===================================================================
// SỬA LỖI TẠI ĐÂY: _MultiSelectChipField được thiết kế lại
// ===================================================================
class _MultiSelectChipField<T> extends StatefulWidget {
  final String label;
  final List<T> allItems;
  final List<T> initialSelectedItems;
  final String Function(T) itemName;
  final ValueChanged<List<T>> onSelectionChanged;
  final bool isReadOnly;

  const _MultiSelectChipField({
    required this.label,
    required this.allItems,
    required this.initialSelectedItems,
    required this.itemName,
    required this.onSelectionChanged,
    this.isReadOnly = false,
  });

  @override
  _MultiSelectChipFieldState<T> createState() =>
      _MultiSelectChipFieldState<T>();
}

class _MultiSelectChipFieldState<T> extends State<_MultiSelectChipField<T>> {
  late List<T> _selectedItems;

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.initialSelectedItems);
  }

  @override
  void didUpdateWidget(covariant _MultiSelectChipField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedItems != oldWidget.initialSelectedItems) {
      _selectedItems = List.from(widget.initialSelectedItems);
    }
  }

  void _showMultiSelectDialog() {
    if (widget.isReadOnly) return;

    showDialog(
      context: context,
      builder: (context) {
        // Sử dụng một List tạm thời để người dùng có thể hủy thay đổi
        final tempSelectedItems = List<T>.from(_selectedItems);
        return StatefulBuilder(builder: (context, menuSetState) {
          return AlertDialog(
            title: Text('Chọn ${widget.label}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true, // Quan trọng để AlertDialog có kích thước hợp lý
                itemCount: widget.allItems.length,
                itemBuilder: (context, index) {
                  final item = widget.allItems[index];
                  final isSelected = tempSelectedItems.contains(item);
                  return CheckboxListTile(
                    title: Text(widget.itemName(item)),
                    value: isSelected,
                    onChanged: (bool? selected) {
                      menuSetState(() {
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedItems = tempSelectedItems;
                    widget.onSelectionChanged(_selectedItems);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Xong'),
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // Hiển thị các chip đã chọn
        if (_selectedItems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _selectedItems
                  .map((item) => Chip(
                label: Text(widget.itemName(item)),
                onDeleted: widget.isReadOnly
                    ? null
                    : () {
                  setState(() {
                    _selectedItems.remove(item);
                  });
                  widget.onSelectionChanged(_selectedItems);
                },
              ))
                  .toList(),
            ),
          ),

        // Nút để mở Dialog
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(_selectedItems.isEmpty
              ? 'Thêm ${widget.label.toLowerCase()}'
              : 'Thay đổi lựa chọn'),
          onPressed: widget.isReadOnly ? null : _showMultiSelectDialog,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        )
      ],
    );
  }
}