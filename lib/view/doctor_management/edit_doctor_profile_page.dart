import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final bool isSelfEdit;

  const EditDoctorProfilePage({
    super.key,
    required this.doctorDetail,
    required this.isSelfEdit,
  });

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

  String? _pendingAvatarUrlForDelete;
  String? _pendingPortraitUrlForDelete;

  // Biến để theo dõi xem đã fetch dữ liệu lần đầu chưa
  bool _initialDataFetched = false;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DoctorVm>().clearUploadError();
        // Fetch dữ liệu lần đầu trong initState (an toàn hơn)
        _fetchInitialDropdownData();
      }
    });

    _degreeController = TextEditingController(text: widget.doctorDetail.degree ?? '');
    _introductionController = _initializeQuillController(widget.doctorDetail.introduction);
    _researchController = _initializeQuillController(widget.doctorDetail.research);
    _positions = List.from(widget.doctorDetail.position ?? []);
    _memberships = List.from(widget.doctorDetail.memberships ?? []);
    _awards = List.from(widget.doctorDetail.awards ?? []);
    _trainings = List.from(widget.doctorDetail.trainingProcess ?? []);
    _experiences = List.from(widget.doctorDetail.experience ?? []);
    _selectedSpecialties = List.from(widget.doctorDetail.specialties);
    _selectedWorkLocations = List.from(widget.doctorDetail.workLocations);
  }

  // Hàm mới để fetch dữ liệu cho dropdowns
  void _fetchInitialDropdownData() {
    if (!_initialDataFetched) {
      // Chỉ fetch nếu chưa fetch lần nào
      Provider.of<SpecialtyVm>(context, listen: false).fetchAllSpecialties();
      Provider.of<LocationWorkVm>(context, listen: false).fetchLocations(forceRefresh: true);
      _initialDataFetched = true; // Đánh dấu đã fetch
    }
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
        final deltaJson = jsonDecode(content);
        final doc = quill.Document.fromJson(deltaJson);
        return quill.QuillController(
            document: doc, selection: const TextSelection.collapsed(offset: 0));
      } catch (e) {
        try {
          final plainText = content
              .replaceAll('<br>', '\n')
              .replaceAll(RegExp(r'<[^>]*>'), '');
          final doc = quill.Document()..insert(0, plainText);
          return quill.QuillController(
              document: doc, selection: const TextSelection.collapsed(offset: 0));
        } catch (plainTextError) {
          print("Error initializing Quill with non-JSON content: $plainTextError");
          return quill.QuillController.basic();
        }
      }
    }
    return quill.QuillController.basic();
  }


  void _saveProfile() {

    if (_formKey.currentState!.validate()) {

      String? getQuillJsonOrNull(quill.QuillController controller) {
        if (controller.document.isEmpty() || controller.document.toPlainText().trim().isEmpty) {
          return null;
        }
        try {
          return jsonEncode(controller.document.toDelta().toJson());
        } catch (e) {
          print("Error encoding Quill JSON: $e");
          return controller.document.toPlainText().trim();
        }
      }

      final introductionJson = getQuillJsonOrNull(_introductionController);
      final researchJson = getQuillJsonOrNull(_researchController);
      final bool isCreating = widget.doctorDetail.profileId == null;

      final doctorVm = context.read<DoctorVm>();

      final Map<String, dynamic> data = {
        'degree': _degreeController.text.trim().isEmpty ? null : _degreeController.text.trim(),
        'introduction': introductionJson,
        'research': researchJson,
        'position': _positions,
        'memberships': _memberships,
        'awards': _awards,
        'trainingProcess': _trainings,
        'experience': _experiences,
        'specialtyIds': _selectedSpecialties.map((e) => e.id).toList(),
        'locationIds': _selectedWorkLocations.map((e) => e.id).toList(),
        'avatarUrl': _pendingAvatarUrlForDelete != null ? null : (doctorVm.selectedAvatarPath == null ? widget.doctorDetail.avatarUrl : '_pending_upload_'),
        'portrait': _pendingPortraitUrlForDelete != null ? null : (doctorVm.selectedPortraitPath == null ? widget.doctorDetail.portrait : '_pending_upload_'),
      };

      if(data['avatarUrl'] == '_pending_upload_' && doctorVm.selectedAvatarPath == null) data.remove('avatarUrl');
      if(data['portrait'] == '_pending_upload_' && doctorVm.selectedPortraitPath == null) data.remove('portrait');


      late Future<bool> future;

      if (widget.isSelfEdit) {
        future = doctorVm.updateSelfProfile(data);
      } else {
        if (isCreating) {
          data['staffAccountId'] = widget.doctorDetail.id;
          future = doctorVm.createDoctorProfile(data);
        } else {
          if (widget.doctorDetail.profileId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: context.theme.destructive,
                content: Text('Lỗi: Không tìm thấy ID hồ sơ để cập nhật.'),
              ),
            );
            return;
          }
          future = doctorVm.updateDoctorProfile(widget.doctorDetail.profileId!, data);
        }
      }

      future.then((success) {
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  backgroundColor: context.theme.green,
                  content: Text('${widget.isSelfEdit ? 'Cập nhật' : (isCreating ? 'Tạo' : 'Cập nhật')} hồ sơ thành công')
              ),
            );
            _pendingAvatarUrlForDelete = null;
            _pendingPortraitUrlForDelete = null;
            Navigator.pop(context, true);
          } else {
            if (doctorVm.error != null && doctorVm.uploadError == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    backgroundColor: context.theme.destructive,
                    content: Text(doctorVm.error!)
                ),
              );
            }
          }
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: context.theme.destructive,
                content: Text('Lỗi không xác định khi lưu: $error')),
          );
        }
      });
    } else {

    }
  }


  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<DoctorVm>().isOffline;
    final doctorVm = context.watch<DoctorVm>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.primary,
        iconTheme: IconThemeData(color: context.theme.primaryForeground),
        title: Text(
          widget.doctorDetail.profileId != null ? 'Chỉnh sửa hồ sơ' : 'Tạo hồ sơ',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        actions: [
          Consumer<DoctorVm>(
            builder: (context, vm, child) {
              final isProcessing = vm.isLoading || vm.isUploadingAvatar || vm.isUploadingPortrait;
              return IconButton(
                icon: isProcessing
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.theme.primaryForeground),
                )
                    : Icon(Icons.save, color: context.theme.primaryForeground),
                onPressed: isProcessing || isOffline ? null : _saveProfile,
                tooltip: isOffline ? 'Không thể lưu khi offline' : (isProcessing ? 'Đang xử lý...' : 'Lưu hồ sơ'),
              );
            },
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: Form(
        key: _formKey,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildAvatarSelector(),
            const SizedBox(height: 24),

            _buildSectionTitle("Thông tin cơ bản", Icons.person_outline),
            _buildTextField(_degreeController, 'Học vị (VD: ThS.BS, PGS.TS.BS)', Icons.school,
                isReadOnly: isOffline),
            const SizedBox(height: 16),
            _QuillEditor(
              label: "Giới thiệu",
              controller: _introductionController,
              isReadOnly: isOffline,
            ),
            const SizedBox(height: 16),
            _buildPortraitSelector(),
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
                label: 'Kinh nghiệm làm việc',
                items: _experiences,
                onChanged: (val) => setState(() => _experiences = val),
                isReadOnly: isOffline),
            _DynamicListInput(
                label: 'Quá trình đào tạo',
                items: _trainings,
                onChanged: (val) => setState(() => _trainings = val),
                isReadOnly: isOffline),
            _DynamicListInput(
                label: 'Giải thưởng & Thành tích',
                items: _awards,
                onChanged: (val) => setState(() => _awards = val),
                isReadOnly: isOffline),
            _DynamicListInput(
                label: 'Thành viên hiệp hội',
                items: _memberships,
                onChanged: (val) => setState(() => _memberships = val),
                isReadOnly: isOffline),
            const SizedBox(height: 24),
            _buildSectionTitle("Chuyên môn & Nơi công tác", Icons.assignment_ind_outlined),
            _buildMultiSelectSpecialties(isOffline),
            const SizedBox(height: 24),
            _buildMultiSelectLocations(isOffline),
            const SizedBox(height: 24),

            Consumer<DoctorVm>(
              builder: (context, vm, child) {
                if (vm.uploadError != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(vm.uploadError!),
                        backgroundColor: context.theme.destructive,
                        duration: const Duration(seconds: 5),
                        action: SnackBarAction(
                          label: 'Đã hiểu',
                          textColor: context.theme.destructiveForeground,
                          onPressed: () => vm.clearUploadError(),
                        ),
                      ));
                    }
                  });
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return Consumer<DoctorVm>(
      builder: (context, doctorVm, child) {
        final currentAvatarUrl = _pendingAvatarUrlForDelete ?? widget.doctorDetail.avatarUrl;
        final selectedAvatarPath = doctorVm.selectedAvatarPath;
        final isUploading = doctorVm.isUploadingAvatar;
        final isOffline = doctorVm.isOffline;

        ImageProvider? imageProvider;
        if (selectedAvatarPath != null) {
          imageProvider = FileImage(File(selectedAvatarPath));
        } else if (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty) {
          imageProvider = CachedNetworkImageProvider(currentAvatarUrl);
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: context.theme.muted.withOpacity(0.5),
                  backgroundImage: imageProvider,
                  child: imageProvider == null
                      ? Icon(Icons.person_outline_rounded, size: 50, color: context.theme.mutedForeground)
                      : null,
                ),
                if (isUploading)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,)),
                  ),
                if (!isUploading)
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: IconButton(
                      icon: CircleAvatar(
                        radius: 18,
                        backgroundColor: context.theme.primary.withOpacity(0.9),
                        child: Icon(Icons.edit, color: context.theme.primaryForeground, size: 18),
                      ),
                      onPressed: isOffline ? null : () {
                        context.read<DoctorVm>().pickAvatarImage();
                        setState(() { _pendingAvatarUrlForDelete = null; });
                      },
                      tooltip: isOffline ? 'Không thể sửa khi offline' : 'Chọn ảnh đại diện',
                    ),
                  ),
                if (!isUploading && (selectedAvatarPath != null || (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty)))
                  Positioned(
                    bottom: -5,
                    left: -5,
                    child: IconButton(
                      icon: CircleAvatar(
                        radius: 18,
                        backgroundColor: context.theme.destructive.withOpacity(0.9),
                        child: Icon(Icons.delete_outline, color: context.theme.destructiveForeground, size: 18),
                      ),
                      onPressed: isOffline ? null : () {
                        setState(() {
                          if (widget.doctorDetail.avatarUrl != null && widget.doctorDetail.avatarUrl!.isNotEmpty) {
                            _pendingAvatarUrlForDelete = widget.doctorDetail.avatarUrl;
                          }
                          // Cần reset selectedAvatarPath trong ViewModel
                          context.read<DoctorVm>().selectedAvatarPath = null;
                          // KHÔNG gọi notifyListeners() trực tiếp từ UI
                        });
                      },
                      tooltip: isOffline ? 'Không thể sửa khi offline' : 'Xóa ảnh đại diện',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ảnh bìa (Portrait)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Consumer<DoctorVm>(
          builder: (context, doctorVm, child) {
            final currentPortraitUrl = _pendingPortraitUrlForDelete ?? widget.doctorDetail.portrait;
            final selectedPortraitPath = doctorVm.selectedPortraitPath;
            final isUploading = doctorVm.isUploadingPortrait;
            final isOffline = doctorVm.isOffline;

            Widget imageWidget;
            if (selectedPortraitPath != null) {
              imageWidget = Image.file(File(selectedPortraitPath), fit: BoxFit.cover);
            } else if (currentPortraitUrl != null && currentPortraitUrl.isNotEmpty) {
              imageWidget = CachedNetworkImage(
                imageUrl: currentPortraitUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: context.theme.muted.withOpacity(0.3)),
                errorWidget: (context, url, error) => Icon(Icons.broken_image, color: context.theme.mutedForeground),
              );
            } else {
              imageWidget = Container(
                color: context.theme.muted.withOpacity(0.3),
                child: Center(child: Icon(Icons.image_outlined, size: 50, color: context.theme.mutedForeground)),
              );
            }

            return AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageWidget,
                  ),
                  if (isUploading)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                    ),
                  if (!isUploading)
                    Positioned(
                        bottom: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selectedPortraitPath != null || (currentPortraitUrl != null && currentPortraitUrl.isNotEmpty))
                              IconButton(
                                style: IconButton.styleFrom(backgroundColor: context.theme.destructive.withOpacity(0.8)),
                                icon: Icon(Icons.delete_outline, color: context.theme.destructiveForeground, size: 20),
                                onPressed: isOffline ? null : () {
                                  setState(() {
                                    if (widget.doctorDetail.portrait != null && widget.doctorDetail.portrait!.isNotEmpty) {
                                      _pendingPortraitUrlForDelete = widget.doctorDetail.portrait;
                                    }
                                    context.read<DoctorVm>().selectedPortraitPath = null;
                                    // KHÔNG gọi notifyListeners() trực tiếp từ UI
                                  });
                                },
                                tooltip: isOffline ? 'Không thể sửa khi offline' : 'Xóa ảnh bìa',
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              style: IconButton.styleFrom(backgroundColor: context.theme.primary.withOpacity(0.8)),
                              icon: Icon(Icons.edit, color: context.theme.primaryForeground, size: 20),
                              onPressed: isOffline ? null : () {
                                context.read<DoctorVm>().pickPortraitImage();
                                setState(() { _pendingPortraitUrlForDelete = null; });
                              },
                              tooltip: isOffline ? 'Không thể sửa khi offline' : 'Chọn ảnh bìa mới',
                            ),
                          ],
                        )
                    ),
                ],
              ),
            );
          },
        ),
      ],
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
      style: TextStyle(color: context.theme.textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.theme.mutedForeground),
        prefixIcon: Icon(icon, color: context.theme.primary, size: 20),
        filled: true,
        fillColor: isReadOnly ? context.theme.muted.withOpacity(0.3) : context.theme.input,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.theme.border.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildMultiSelectSpecialties(bool isReadOnly) {
    return Consumer<SpecialtyVm>(
      builder: (context, specialtyVm, child) {
        // **SỬA LỖI:** Không gọi fetch trực tiếp trong builder hoặc addPostFrameCallback trong builder
        if (specialtyVm.allSpecialties.isEmpty && !specialtyVm.isLoading && !_initialDataFetched) {
          // Có thể hiển thị loading indicator ở đây thay vì gọi fetch
          return const Center(child: Text("Đang tải danh sách chuyên khoa..."));
        }
        return _MultiSelectChipField<Specialty>(
          label: 'Chuyên khoa',
          allItems: specialtyVm.allSpecialties,
          initialSelectedItems: _selectedSpecialties,
          itemName: (specialty) => specialty.name,
          onSelectionChanged: (selectedItems) {
            if (!isReadOnly) {
              setState(() => _selectedSpecialties = selectedItems);
            }
          },
          isReadOnly: isReadOnly,
        );
      },
    );
  }

  Widget _buildMultiSelectLocations(bool isReadOnly) {
    return Consumer<LocationWorkVm>(
      builder: (context, locationVm, child) {
        // **SỬA LỖI:** Không gọi fetch trực tiếp trong builder hoặc addPostFrameCallback trong builder
        if (locationVm.locations.isEmpty && !locationVm.isLoading && !_initialDataFetched) {
          return const Center(child: Text("Đang tải danh sách địa điểm..."));
        }
        return _MultiSelectChipField<WorkLocation>(
          label: 'Nơi công tác',
          allItems: locationVm.locations,
          initialSelectedItems: _selectedWorkLocations,
          itemName: (location) => location.name,
          onSelectionChanged: (selectedItems) {
            if (!isReadOnly) {
              setState(() => _selectedWorkLocations = selectedItems);
            }
          },
          isReadOnly: isReadOnly,
        );
      },
    );
  }
}

// === WIDGET QUILL ĐÃ SỬA LỖI ===
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
            color: isReadOnly ? theme.muted.withOpacity(0.3) : theme.card,
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
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: quill.QuillSimpleToolbar( // Sử dụng QuillSimpleToolbar
                      controller: controller,
                      config: const quill.QuillSimpleToolbarConfig( // Sử dụng config cũ
                        toolbarSize: 24,
                        toolbarSectionSpacing: 4,
                        showAlignmentButtons: true,
                        showFontSize: false,
                        showSubscript: false,
                        showSuperscript: false,
                        showInlineCode: false,
                        showDividers: true,
                        multiRowsDisplay: false,
                        showBoldButton: true,
                        showItalicButton: true,
                        showUnderLineButton: true,
                        showStrikeThrough: true,
                        showClearFormat: true,
                        showHeaderStyle: true,
                        showListBullets: true,
                        showListNumbers: true,
                        showListCheck: true,
                        showCodeBlock: false,
                        showQuote: true,
                        showIndent: true,
                        showLink: true,
                        showUndo: true,
                        showRedo: true,
                      ),
                    ),
                  ),
                if (!isReadOnly) const Divider(height: 1),
                Container(
                  constraints: const BoxConstraints(minHeight: 200, maxHeight: 400),
                  color: isReadOnly ? theme.muted.withOpacity(0.3) : theme.input,
                  padding: const EdgeInsets.all(12),
                  child: quill.QuillEditor.basic( // Sử dụng basic editor
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
// =============================

// === WIDGET CON _DynamicListInput GIỮ NGUYÊN ===
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
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.items.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 0,
                color: context.theme.input.withOpacity(0.7),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: context.theme.border.withOpacity(0.5))
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  title: Text(widget.items[index], style: TextStyle(color: context.theme.textColor)),
                  trailing: widget.isReadOnly ? null : IconButton(
                    icon: Icon(Icons.close, color: context.theme.destructive, size: 18,),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _removeItem(index),
                  ),
                ),
              );
            },
          ),
        if (!widget.isReadOnly)
          TextFormField(
            controller: _textController,
            style: TextStyle(color: context.theme.textColor),
            decoration: InputDecoration(
              hintText: 'Thêm ${widget.label.toLowerCase()}...',
              hintStyle: TextStyle(color: context.theme.mutedForeground),
              filled: true,
              fillColor: context.theme.input,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.theme.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: IconButton(
                icon: Icon(Icons.add_circle_outline, color: context.theme.primary),
                onPressed: _addItem,
              ),
            ),
            onFieldSubmitted: (_) => _addItem(),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
// ===========================================

// === WIDGET CON _MultiSelectChipField GIỮ NGUYÊN ===
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
    bool listsAreEqual = _compareLists(widget.initialSelectedItems, _selectedItems);

    if (!listsAreEqual) {
      _selectedItems = List.from(widget.initialSelectedItems);
    }
    if (widget.allItems.isNotEmpty && _selectedItems.isNotEmpty) {
      _selectedItems.removeWhere((selected) =>
      !widget.allItems.any((allItem) => (allItem as dynamic).id == (selected as dynamic).id));
    }
  }

  bool _compareLists(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    var ids1 = list1.map((e) => (e as dynamic).id).toSet();
    var ids2 = list2.map((e) => (e as dynamic).id).toSet();
    return ids1.length == ids2.length && ids1.containsAll(ids2);
  }


  void _showMultiSelectDialog() {
    if (widget.isReadOnly) return;

    showDialog(
      context: context,
      builder: (context) {
        final tempSelectedItems = List<T>.from(_selectedItems);
        String searchQuery = "";

        return StatefulBuilder(builder: (context, menuSetState) {
          final filteredItems = widget.allItems.where((item) {
            final name = widget.itemName(item).toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return AlertDialog(
            backgroundColor: context.theme.popover,
            title: Text('Chọn ${widget.label}', style: TextStyle(color: context.theme.popoverForeground)),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    style: TextStyle(color: context.theme.popoverForeground),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm...',
                      hintStyle: TextStyle(color: context.theme.mutedForeground),
                      prefixIcon: Icon(Icons.search, color: context.theme.mutedForeground),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) {
                      menuSetState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: widget.allItems.isEmpty
                      ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(child: Text("Không có dữ liệu", style: TextStyle(color: context.theme.popoverForeground)))
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isSelected = tempSelectedItems.any((selectedItem) => (selectedItem as dynamic).id == (item as dynamic).id);
                      return CheckboxListTile(
                        title: Text(widget.itemName(item), style: TextStyle(color: context.theme.popoverForeground)),
                        value: isSelected,
                        activeColor: context.theme.primary,
                        checkColor: context.theme.primaryForeground,
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy', style: TextStyle(color: context.theme.mutedForeground)),
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
    final sortedSelectedItems = List<T>.from(_selectedItems)
      ..sort((a, b) => widget.itemName(a).compareTo(widget.itemName(b)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.theme.textColor)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isReadOnly ? context.theme.muted.withOpacity(0.3) : context.theme.input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.theme.border),
          ),
          child: _selectedItems.isEmpty
              ? GestureDetector(
              onTap: widget.isReadOnly ? null : _showMultiSelectDialog,
              child: Center(
                  child: Text(
                    'Chưa có ${widget.label.toLowerCase()} nào được chọn',
                    style: TextStyle(color: context.theme.mutedForeground),
                  )
              )
          )
              : SingleChildScrollView(
            child: Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: sortedSelectedItems
                  .map((item) => Chip(
                label: Text(widget.itemName(item)),
                backgroundColor: context.theme.primary.withOpacity(0.15),
                labelStyle: TextStyle(color: context.theme.primary, fontWeight: FontWeight.w500),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                deleteIcon: Icon(Icons.close, size: 16, color: context.theme.destructive.withOpacity(0.7)),
                onDeleted: widget.isReadOnly
                    ? null
                    : () {
                  setState(() {
                    _selectedItems.removeWhere((i) => (i as dynamic).id == (item as dynamic).id);
                    widget.onSelectionChanged(_selectedItems);
                  });
                },
              ))
                  .toList(),
            ),
          ),
        ),

        if (!widget.isReadOnly) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
              icon: Icon(_selectedItems.isEmpty ? Icons.add : Icons.edit_outlined, size: 18,),
              label: Text(_selectedItems.isEmpty
                  ? 'Thêm ${widget.label.toLowerCase()}'
                  : 'Chỉnh sửa lựa chọn'),
              onPressed: _showMultiSelectDialog,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                foregroundColor: context.theme.primary,
                side: BorderSide(color: context.theme.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ).copyWith(
                foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return context.theme.mutedForeground;
                      }
                      return context.theme.primary;
                    }),
                side: MaterialStateProperty.resolveWith<BorderSide?>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.disabled)) {
                        return BorderSide(color: context.theme.border);
                      }
                      return BorderSide(color: context.theme.primary.withOpacity(0.5));
                    }),
              )
          )
        ]
      ],
    );
  }
}