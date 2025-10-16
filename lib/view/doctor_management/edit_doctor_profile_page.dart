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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
        context.read<LocationWorkVm>().fetchLocations(forceRefresh: true);
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
      setState(() => _isLoading = true);
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
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: success ? context.theme.green : context.theme.destructive,
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
          _isLoading
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            onPressed: isOffline ? null : _saveProfile,
            tooltip: isOffline ? 'Không thể lưu khi offline' : 'Lưu hồ sơ',
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle("Thông tin cơ bản", Icons.person_outline),
            _buildTextField(_degreeController, 'Học vị', Icons.school,
                isReadOnly: isOffline),
            const SizedBox(height: 16),
            _QuillEditor(
              label: "Giới thiệu",
              controller: _introductionController,
              isReadOnly: isOffline,
            ),
            const SizedBox(height: 16),
            _QuillEditor(
              label: "Nghiên cứu khoa học",
              controller: _researchController,
              isReadOnly: isOffline,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle("Kinh nghiệm & Thành tựu", Icons.work_outline),
            _DynamicListInput(
                label: 'Chức vụ',
                items: _positions,
                onChanged: (val) => setState(() => _positions = val),
                isReadOnly: isOffline),
            _DynamicListInput(
                label: 'Kinh nghiệm',
                items: _experiences,
                onChanged: (val) => setState(() => _experiences = val),
                isReadOnly: isOffline),
            _DynamicListInput(
                label: 'Quá trình đào tạo',
                items: _trainings,
                onChanged: (val) => setState(() => _trainings = val),
                isReadOnly: isOffline),
            _DynamicListInput(
                label: 'Giải thưởng',
                items: _awards,
                onChanged: (val) => setState(() => _awards = val),
                isReadOnly: isOffline),
            _DynamicListInput(
                label: 'Thành viên hiệp hội',
                items: _memberships,
                onChanged: (val) => setState(() => _memberships = val),
                isReadOnly: isOffline),
            const SizedBox(height: 24),
            _buildSectionTitle("Phân công", Icons.assignment_ind_outlined),
            _buildMultiSelectSpecialties(isOffline),
            const SizedBox(height: 24),
            _buildMultiSelectLocations(isOffline),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: context.theme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
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
        prefixIcon: Icon(icon, color: context.theme.primary, size: 20),
        filled: true,
        fillColor: context.theme.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.theme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.theme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.theme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildMultiSelectSpecialties(bool isReadOnly) {
    return Consumer<SpecialtyVm>(
      builder: (context, specialtyVm, child) {
        return _MultiSelectChipField<Specialty>(
          label: 'Chuyên khoa',
          // SỬA LỖI: Sử dụng getter 'specialties'
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
          // SỬA LỖI: Sử dụng getter 'locations'
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
            color: theme.card,
            boxShadow: [
              BoxShadow(
                color: theme.textColor.withOpacity(0.05),
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
                        toolbarSize: 24,
                        toolbarSectionSpacing: 4,
                        showAlignmentButtons: true,
                        showFontSize: false,
                        showSubscript: false,
                        showSuperscript: false,
                        showInlineCode: false,
                        showDividers: true,
                        multiRowsDisplay: false,
                      ),
                    ),
                  ),
                if (!isReadOnly) const Divider(height: 1),
                Container(
                  height: 250,
                  color: isReadOnly ? theme.input : theme.card,
                  padding: const EdgeInsets.all(8),
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
    if (widget.isReadOnly || _textController.text.trim().isEmpty) return;

    setState(() {
      widget.items.add(_textController.text.trim());
      widget.onChanged(widget.items);
      _textController.clear();
    });
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
        if (widget.items.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 0,
                color: context.theme.input,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: context.theme.border)
                ),
                child: ListTile(
                  title: Text(widget.items[index]),
                  trailing: widget.isReadOnly ? null : IconButton(
                    icon: Icon(Icons.delete_outline, color: context.theme.destructive),
                    onPressed: () => _removeItem(index),
                  ),
                ),
              );
            },
          ),
        if (!widget.isReadOnly)
          TextFormField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Thêm ${widget.label.toLowerCase()}',
              filled: true,
              fillColor: context.theme.input,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.theme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.theme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.theme.primary, width: 1.5),
              ),
              suffixIcon: IconButton(
                icon: Icon(Icons.add_circle, color: context.theme.primary),
                onPressed: _addItem,
              ),
            ),
            onFieldSubmitted: (_) => _addItem(),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

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
    if(widget.allItems != oldWidget.allItems) {
      _selectedItems.removeWhere((item) => !widget.allItems.any((allItem) => (allItem as dynamic).id == (item as dynamic).id));
    }
  }

  void _showMultiSelectDialog() {
    if (widget.isReadOnly) return;

    showDialog(
      context: context,
      builder: (context) {
        final tempSelectedItems = List<T>.from(_selectedItems);
        return StatefulBuilder(builder: (context, menuSetState) {
          return AlertDialog(
            title: Text('Chọn ${widget.label}'),
            content: SizedBox(
              width: double.maxFinite,
              child: widget.allItems.isEmpty
                  ? const Center(child: Text("Không có dữ liệu"))
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allItems.length,
                itemBuilder: (context, index) {
                  final item = widget.allItems[index];
                  final isSelected = tempSelectedItems.any((selectedItem) => (selectedItem as dynamic).id == (item as dynamic).id);
                  return CheckboxListTile(
                    title: Text(widget.itemName(item)),
                    value: isSelected,
                    activeColor: context.theme.primary,
                    onChanged: (bool? selected) {
                      menuSetState(() {
                        if (selected == true) {
                          tempSelectedItems.add(item);
                        } else {
                          tempSelectedItems.removeWhere((selectedItem) => (selectedItem as dynamic).id == (item as dynamic).id);
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
                style: ElevatedButton.styleFrom(backgroundColor: context.theme.primary, foregroundColor: context.theme.primaryForeground),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.theme.input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.theme.border),
          ),
          child: _selectedItems.isEmpty
              ? Text('Chưa có ${widget.label.toLowerCase()} nào được chọn', style: TextStyle(color: context.theme.mutedForeground),)
              : Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _selectedItems
                .map((item) => Chip(
              label: Text(widget.itemName(item)),
              backgroundColor: context.theme.primary.withOpacity(0.1),
              labelStyle: TextStyle(color: context.theme.primary, fontWeight: FontWeight.w500),
              onDeleted: widget.isReadOnly
                  ? null
                  : () {
                setState(() {
                  _selectedItems.remove(item);
                  widget.onSelectionChanged(_selectedItems);
                });
              },
              deleteIconColor: context.theme.destructive,
            ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(_selectedItems.isEmpty
              ? 'Thêm ${widget.label.toLowerCase()}'
              : 'Thay đổi lựa chọn'),
          onPressed: widget.isReadOnly ? null : _showMultiSelectDialog,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: context.theme.primary,
            side: BorderSide(color: context.theme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        )
      ],
    );
  }
}