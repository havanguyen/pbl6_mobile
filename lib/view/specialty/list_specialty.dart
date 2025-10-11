import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../shared/widgets/widget/specialty_delete_confirm.dart';

class ListSpecialtyPage extends StatefulWidget {
  const ListSpecialtyPage({super.key});

  @override
  State<ListSpecialtyPage> createState() => _ListSpecialtyPageState();
}

class _ListSpecialtyPageState extends State<ListSpecialtyPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
      }
    });
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_debounceSearch);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SpecialtyVm>().fetchSpecialties();
    }
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        context.read<SpecialtyVm>().updateSearchQuery(_searchController.text);
      }
    });
  }

  void _showDeleteDialog(Specialty specialty) {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteSpecialtyConfirmationDialog(
        specialty: specialty.toJson(),
        onDeleteSuccess: () {
          context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
        },
        snackbarService: snackbarService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final specialtyVm = context.watch<SpecialtyVm>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Chuyên khoa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: specialtyVm.isLoading
                ? null
                : () => specialtyVm.fetchSpecialties(forceRefresh: true),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndActions(specialtyVm.isOffline),
          if (specialtyVm.isOffline && specialtyVm.error != null)
            Container(
              width: double.infinity,
              color: Colors.amber,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                specialtyVm.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          if (specialtyVm.isLoading && specialtyVm.specialties.isNotEmpty)
            const LinearProgressIndicator(),
          Expanded(
            child: Builder(
              builder: (context) {
                if (specialtyVm.isLoading && specialtyVm.specialties.isEmpty) {
                  return _buildShimmerList();
                }
                if (specialtyVm.error != null &&
                    specialtyVm.specialties.isEmpty &&
                    !specialtyVm.isOffline) {
                  return Center(child: Text('Lỗi: ${specialtyVm.error}'));
                }
                if (specialtyVm.specialties.isEmpty) {
                  return _buildEmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      specialtyVm.fetchSpecialties(forceRefresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: specialtyVm.specialties.length +
                        (specialtyVm.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == specialtyVm.specialties.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final specialty = specialtyVm.specialties[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildSpecialtyCard(
                                specialty, specialtyVm.isOffline),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActions(bool isOffline) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: context.theme.textColor),
            decoration: InputDecoration(
              labelText: 'Tìm kiếm chuyên khoa',
              labelStyle: TextStyle(color: context.theme.mutedForeground),
              prefixIcon: Icon(Icons.search, color: context.theme.primary),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: context.theme.primary, width: 1.5),
              ),
              filled: true,
              fillColor: context.theme.input,
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: context.theme.primary),
                onPressed: () {
                  _searchController.clear();
                  context.read<SpecialtyVm>().updateSearchQuery('');
                },
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: isOffline
                ? null
                : () async {
              final result =
              await Navigator.pushNamed(context, Routes.createSpecialty);
              if (result == true && mounted) {
                context
                    .read<SpecialtyVm>()
                    .fetchSpecialties(forceRefresh: true);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Thêm chuyên khoa mới'),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primary,
              foregroundColor: context.theme.primaryForeground,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).copyWith(
              backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return Colors.grey;
                  }
                  return context.theme.primary;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medical_services_outlined,
            size: 80,
            color: context.theme.mutedForeground,
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty
                ? 'Chưa có chuyên khoa nào'
                : 'Không tìm thấy chuyên khoa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Nhấn nút "Thêm chuyên khoa mới" để bắt đầu.'
                : 'Hãy thử với từ khóa khác.',
            style: TextStyle(color: context.theme.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: context.theme.muted,
      highlightColor: context.theme.input,
      child: ListView.builder(
        itemCount: 8,
        padding: const EdgeInsets.all(8),
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const ListTile(
            leading: CircleAvatar(radius: 28, backgroundColor: Colors.white),
            title: SizedBox(height: 16, width: 150),
            subtitle: SizedBox(height: 12, width: 100),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyCard(Specialty specialty, bool isOffline) {
    return Slidable(
      key: ValueKey(specialty.id),
      endActionPane: isOffline
          ? null
          : ActionPane(
        motion: const BehindMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final result = await Navigator.pushNamed(
                context,
                Routes.updateSpecialty,
                arguments: specialty.toJson(),
              );
              if (result == true && mounted) {
                context
                    .read<SpecialtyVm>()
                    .fetchSpecialties(forceRefresh: true);
              }
            },
            backgroundColor: context.theme.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Sửa',
          ),
          SlidableAction(
            onPressed: (context) => _showDeleteDialog(specialty),
            backgroundColor: context.theme.destructive,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Xóa',
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final result = await Navigator.pushNamed(
              context,
              Routes.specialtyDetail,
              arguments: specialty.toJson(),
            );
            if (result == true && mounted) {
              context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: context.theme.primary.withOpacity(0.1),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: context.theme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialty.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.theme.textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Số phần thông tin: ${specialty.infoSectionsCount}',
                        style: TextStyle(
                          color: context.theme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: context.theme.mutedForeground,
                  size: 16,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}