import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
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

import '../../shared/widgets/widget/dynamic_list_input.dart';
import '../../shared/widgets/widget/multi_select_chip.dart';
import '../../shared/widgets/widget/quill_edittor.dart';

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

class _EditDoctorProfilePageState extends State<EditDoctorProfilePage>
    with SingleTickerProviderStateMixin {
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

  bool _initialDataFetched = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DoctorVm>().clearUploadError();
        _fetchInitialDropdownData();
      }
    });

    _degreeController =
        TextEditingController(text: widget.doctorDetail.degree ?? '');
    _introductionController =
        _initializeQuillController(widget.doctorDetail.introduction);
    _researchController =
        _initializeQuillController(widget.doctorDetail.research);
    _positions = List.from(widget.doctorDetail.position);
    _memberships = List.from(widget.doctorDetail.memberships);
    _awards = List.from(widget.doctorDetail.awards);
    _trainings = List.from(widget.doctorDetail.trainingProcess);
    _experiences = List.from(widget.doctorDetail.experience);
    _selectedSpecialties = List.from(widget.doctorDetail.specialties);
    _selectedWorkLocations = List.from(widget.doctorDetail.workLocations);
  }

  void _fetchInitialDropdownData() {
    if (!_initialDataFetched) {
      print("--- DEBUG: _fetchInitialDropdownData ---");
      Provider.of<SpecialtyVm>(context, listen: false).fetchAllSpecialties();
      Provider.of<LocationWorkVm>(context, listen: false).fetchLocations(
        forceRefresh: true,
        limit: 1000,
      );
      _initialDataFetched = true;
    }
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
    print("--- DEBUG: _saveProfile CALLED ---");

    if (_formKey.currentState!.validate()) {
      print("--- DEBUG: Form is VALID ---");

      String? getQuillJsonOrNull(quill.QuillController controller) {
        if (controller.document.isEmpty() ||
            controller.document.toPlainText().trim().isEmpty) {
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

      final doctorVm = context.read<DoctorVm>();

      final Map<String, dynamic> data = {
        'degree': _degreeController.text.trim().isEmpty
            ? null
            : _degreeController.text.trim(),
        'introduction': introductionJson,
        'research': researchJson,
        'position': _positions,
        'memberships': _memberships,
        'awards': _awards,
        'trainingProcess': _trainings,
        'experience': _experiences,
        'specialtyIds': _selectedSpecialties.map((e) => e.id).toList(),
        'locationIds': _selectedWorkLocations.map((e) => e.id).toList(),
        'avatarUrl': _pendingAvatarUrlForDelete != null
            ? null
            : (doctorVm.selectedAvatarPath == null
            ? widget.doctorDetail.avatarUrl
            : '_pending_upload_'),
        'portrait': _pendingPortraitUrlForDelete != null
            ? null
            : (doctorVm.selectedPortraitPath == null
            ? widget.doctorDetail.portrait
            : '_pending_upload_'),
      };

      if (data['avatarUrl'] == '_pending_upload_' &&
          doctorVm.selectedAvatarPath == null) data.remove('avatarUrl');
      if (data['portrait'] == '_pending_upload_' &&
          doctorVm.selectedPortraitPath == null) data.remove('portrait');

      print("--- DEBUG: Data being SENT ---");
      print(jsonEncode(data));
      print("--- END DEBUG: Data being SENT ---");

      late Future<bool> future;

      if (widget.isSelfEdit) {
        print("--- DEBUG: Calling updateSelfProfile ---");
        future = doctorVm.updateSelfProfile(data);
      } else {
        print("--- DEBUG: Calling updateDoctorProfile ---");
        future =
            doctorVm.updateDoctorProfile(widget.doctorDetail.profileId, data);
      }

      future.then((success) {
        if (mounted) {
          print("--- DEBUG: Save Future COMPLETED. Success: $success ---");
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  backgroundColor: context.theme.green,
                  content: Text(
                      '${widget.isSelfEdit ? 'Cập nhật' : ('Cập nhật')} hồ sơ thành công')),
            );
            _pendingAvatarUrlForDelete = null;
            _pendingPortraitUrlForDelete = null;
            Navigator.pop(context, true);
          } else {
            print(
                "--- DEBUG: Save FAILED. VM Error: ${doctorVm.error} | Upload Error: ${doctorVm.uploadError} ---");
            if (doctorVm.error != null && doctorVm.uploadError == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    backgroundColor: context.theme.destructive,
                    content: Text(doctorVm.error!)),
              );
            }
          }
        }
      }).catchError((error) {
        if (mounted) {
          print("--- DEBUG: Save Future ERRORED ---");
          print(error.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: context.theme.destructive,
                content: Text('Lỗi không xác định khi lưu: $error')),
          );
        }
      });
    } else {
      print("--- DEBUG: Form is INVALID ---");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = context.watch<DoctorVm>().isOffline;
    final doctorVm = context.watch<DoctorVm>();
    final isProcessing =
        doctorVm.isLoading || doctorVm.isUploadingAvatar || doctorVm.isUploadingPortrait;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.primary,
        iconTheme: IconThemeData(color: context.theme.primaryForeground),
        title: Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.theme.primaryForeground,
          unselectedLabelColor: context.theme.primaryForeground.withOpacity(0.7),
          indicatorColor: context.theme.primaryForeground,
          tabs: const [
            Tab(text: 'Hồ sơ chính', icon: Icon(Icons.person_pin)),
            Tab(text: 'Chi tiết', icon: Icon(Icons.article)),
            Tab(text: 'Chuyên môn', icon: Icon(Icons.medical_services)),
          ],
        ),
      ),
      backgroundColor: context.theme.bg,
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildMainProfileTab(isOffline),
            _buildDetailsTab(isOffline),
            _buildRelationsTab(isOffline),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('edit_profile_save_button'),
        onPressed: isProcessing || isOffline ? null : _saveProfile,
        tooltip: isOffline
            ? 'Không thể lưu khi offline'
            : (isProcessing ? 'Đang xử lý...' : 'Lưu hồ sơ'),
        backgroundColor: isOffline ? context.theme.muted : context.theme.primary,
        icon: isProcessing
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.theme.primaryForeground),
        )
            : Icon(Icons.save, color: context.theme.primaryForeground),
        label: Text(
          isProcessing ? 'Đang lưu...' : 'Lưu hồ sơ',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
      ),
    );
  }

  Widget _buildMainProfileTab(bool isOffline) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildAvatarSelector(),
        const SizedBox(height: 24),
        _buildPortraitSelector(),
        const SizedBox(height: 24),
        _buildCard(
          child: _buildTextField(_degreeController, 'Học vị (VD: ThS.BS)',
              Icons.school,
              isReadOnly: isOffline),
        ),
        const SizedBox(height: 16),
        _buildCard(
          child: QuillEditor(
            label: "Giới thiệu",
            controller: _introductionController,
            isReadOnly: isOffline,
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          child: QuillEditor(
            label: "Nghiên cứu khoa học",
            controller: _researchController,
            isReadOnly: isOffline,
          ),
        ),
        _buildErrorSnackbarListener(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDetailsTab(bool isOffline) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(
          child: DynamicListInput(
              label: 'Chức vụ',
              items: _positions,
              onChanged: (val) => setState(() => _positions = val),
              isReadOnly: isOffline),
        ),
        const SizedBox(height: 16),
        _buildCard(
          child: DynamicListInput(
              label: 'Kinh nghiệm làm việc',
              items: _experiences,
              onChanged: (val) => setState(() => _experiences = val),
              isReadOnly: isOffline),
        ),
        const SizedBox(height: 16),
        _buildCard(
          child: DynamicListInput(
              label: 'Quá trình đào tạo',
              items: _trainings,
              onChanged: (val) => setState(() => _trainings = val),
              isReadOnly: isOffline),
        ),
        const SizedBox(height: 16),
        _buildCard(
          child: DynamicListInput(
              label: 'Giải thưởng & Thành tích',
              items: _awards,
              onChanged: (val) => setState(() => _awards = val),
              isReadOnly: isOffline),
        ),
        const SizedBox(height: 16),
        _buildCard(
          child: DynamicListInput(
              label: 'Thành viên hiệp hội',
              items: _memberships,
              onChanged: (val) => setState(() => _memberships = val),
              isReadOnly: isOffline),
        ),
        _buildErrorSnackbarListener(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildRelationsTab(bool isOffline) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildCard(child: _buildMultiSelectSpecialties(isOffline)),
        const SizedBox(height: 24),
        _buildCard(child: _buildMultiSelectLocations(isOffline)),
        _buildErrorSnackbarListener(),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 1,
      shadowColor: context.theme.popover.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.theme.border, width: 0.5),
      ),
      color: context.theme.card,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildAvatarSelector() {
    return Consumer<DoctorVm>(
      builder: (context, doctorVm, child) {
        final currentAvatarUrl =
            _pendingAvatarUrlForDelete ?? widget.doctorDetail.avatarUrl;
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
          child: Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: context.theme.muted.withOpacity(0.5),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? Icon(Icons.person_outline_rounded,
                    size: 60, color: context.theme.mutedForeground)
                    : null,
              ),
              if (isUploading)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )),
                ),
              if (!isUploading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: context.theme.primary.withOpacity(0.9),
                    child: IconButton(
                      key: const ValueKey('edit_profile_avatar_picker'),
                      icon: Icon(Icons.edit,
                          color: context.theme.primaryForeground, size: 20),
                      onPressed: isOffline
                          ? null
                          : () {
                        print("--- DEBUG: pickAvatarImage CALLED ---");
                        context.read<DoctorVm>().pickAvatarImage();
                        setState(() {
                          _pendingAvatarUrlForDelete = null;
                        });
                      },
                      tooltip: isOffline
                          ? 'Không thể sửa khi offline'
                          : 'Chọn ảnh đại diện',
                    ),
                  ),
                ),
              if (!isUploading &&
                  (selectedAvatarPath != null ||
                      (currentAvatarUrl != null && currentAvatarUrl.isNotEmpty)))
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: context.theme.destructive.withOpacity(0.9),
                    child: IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: context.theme.destructiveForeground, size: 20),
                      onPressed: isOffline
                          ? null
                          : () {
                        print("--- DEBUG: Deleting Avatar ---");
                        setState(() {
                          if (widget.doctorDetail.avatarUrl != null &&
                              widget.doctorDetail.avatarUrl!.isNotEmpty) {
                            _pendingAvatarUrlForDelete =
                                widget.doctorDetail.avatarUrl;
                            print(
                                "--- DEBUG: Set _pendingAvatarUrlForDelete to: $_pendingAvatarUrlForDelete");
                          }
                          context.read<DoctorVm>().selectedAvatarPath =
                          null;
                          print(
                              "--- DEBUG: Set selectedAvatarPath to null ---");
                        });
                      },
                      tooltip: isOffline
                          ? 'Không thể sửa khi offline'
                          : 'Xóa ảnh đại diện',
                    ),
                  ),
                ),
            ],
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
            final currentPortraitUrl =
                _pendingPortraitUrlForDelete ?? widget.doctorDetail.portrait;
            final selectedPortraitPath = doctorVm.selectedPortraitPath;
            final isUploading = doctorVm.isUploadingPortrait;
            final isOffline = doctorVm.isOffline;

            Widget imageWidget;
            if (selectedPortraitPath != null) {
              imageWidget =
                  Image.file(File(selectedPortraitPath), fit: BoxFit.cover);
            } else if (currentPortraitUrl != null &&
                currentPortraitUrl.isNotEmpty) {
              imageWidget = CachedNetworkImage(
                imageUrl: currentPortraitUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: context.theme.muted.withOpacity(0.3)),
                errorWidget: (context, url, error) =>
                    Icon(Icons.broken_image, color: context.theme.mutedForeground),
              );
            } else {
              imageWidget = Container(
                color: context.theme.muted.withOpacity(0.3),
                child: Center(
                    child: Icon(Icons.image_outlined,
                        size: 50, color: context.theme.mutedForeground)),
              );
            }

            return AspectRatio(
              aspectRatio: 16 / 9,
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: context.theme.border, width: 0.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    imageWidget,
                    if (isUploading)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)),
                      ),
                    if (!isUploading)
                      Positioned(
                          bottom: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (selectedPortraitPath != null ||
                                  (currentPortraitUrl != null &&
                                      currentPortraitUrl.isNotEmpty))
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: context.theme.destructive
                                      .withOpacity(0.8),
                                  child: IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        color:
                                        context.theme.destructiveForeground,
                                        size: 18),
                                    onPressed: isOffline
                                        ? null
                                        : () {
                                      print(
                                          "--- DEBUG: Deleting Portrait ---");
                                      setState(() {
                                        if (widget.doctorDetail.portrait !=
                                            null &&
                                            widget.doctorDetail.portrait!
                                                .isNotEmpty) {
                                          _pendingPortraitUrlForDelete =
                                              widget.doctorDetail.portrait;
                                          print(
                                              "--- DEBUG: Set _pendingPortraitUrlForDelete to: $_pendingPortraitUrlForDelete");
                                        }
                                        context
                                            .read<DoctorVm>()
                                            .selectedPortraitPath = null;
                                        print(
                                            "--- DEBUG: Set selectedPortraitPath to null ---");
                                      });
                                    },
                                    tooltip: isOffline
                                        ? 'Không thể sửa khi offline'
                                        : 'Xóa ảnh bìa',
                                  ),
                                ),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                context.theme.primary.withOpacity(0.8),
                                child: IconButton(
                                  icon: Icon(Icons.edit,
                                      color: context.theme.primaryForeground,
                                      size: 18),
                                  onPressed: isOffline
                                      ? null
                                      : () {
                                    print(
                                        "--- DEBUG: pickPortraitImage CALLED ---");
                                    context
                                        .read<DoctorVm>()
                                        .pickPortraitImage();
                                    setState(() {
                                      _pendingPortraitUrlForDelete = null;
                                    });
                                  },
                                  tooltip: isOffline
                                      ? 'Không thể sửa khi offline'
                                      : 'Chọn ảnh bìa mới',
                                ),
                              ),
                            ],
                          )),
                  ],
                ),
              ),
            );
          },
        ),
      ],
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
        fillColor: isReadOnly
            ? context.theme.muted.withOpacity(0.3)
            : context.theme.input.withOpacity(0.5),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildMultiSelectSpecialties(bool isReadOnly) {
    return Consumer<SpecialtyVm>(
      builder: (context, specialtyVm, child) {
        if (specialtyVm.isLoadingAll) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text("Đang tải danh sách chuyên khoa..."),
                ],
              ),
            ),
          );
        }

        print("--- DEBUG: _buildMultiSelectSpecialties ---");
        print(
            "--- All Specialties from VM: ${specialtyVm.allSpecialties.length} ---");
        print(
            "--- Initial Selected Specialties: ${_selectedSpecialties.length} ---");

        return MultiSelectChipField<Specialty>(
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
        if (locationVm.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text("Đang tải danh sách địa điểm..."),
                ],
              ),
            ),
          );
        }

        print("--- DEBUG: _buildMultiSelectLocations ---");
        print("--- All Locations from VM: ${locationVm.locations.length} ---");
        print(
            "--- Initial Selected Locations: ${_selectedWorkLocations.length} ---");

        return MultiSelectChipField<WorkLocation>(
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

  Widget _buildErrorSnackbarListener() {
    return Consumer<DoctorVm>(
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
    );
  }
}