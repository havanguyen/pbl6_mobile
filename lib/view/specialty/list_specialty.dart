
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pbl6mobile/model/entities/specialty.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../shared/widgets/widget/specialty_delete_confirm.dart';
import '../../view_model/location_work_management/snackbar_service.dart';

class ListSpecialtyPage extends StatefulWidget {
  const ListSpecialtyPage({super.key});

  @override
  State<ListSpecialtyPage> createState() => _ListSpecialtyPageState();
}

class _ListSpecialtyPageState extends State<ListSpecialtyPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SpecialtyVm>().fetchSpecialties();
    }
  }

  void _showDeleteDialog(Specialty specialty) {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteSpecialtyConfirmationDialog(
        specialty: specialty.toJson(),
        onDeleteSuccess: () {},
        snackbarService: snackbarService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Chuyên khoa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true),
          )
        ],
      ),
      body: Consumer<SpecialtyVm>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.specialties.isEmpty) {
            return _buildShimmerList();
          }
          if (provider.error != null && provider.specialties.isEmpty) {
            return Center(child: Text('Lỗi: ${provider.error}'));
          }
          if (provider.specialties.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: provider.specialties.length +
                  (provider.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == provider.specialties.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final specialty = provider.specialties[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildSpecialtyCard(specialty),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result =
          await Navigator.pushNamed(context, Routes.createSpecialty);
          if (result == true && mounted) {
            context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
          }
        },
        backgroundColor: context.theme.primary,
        child: const Icon(Icons.add, color: Colors.white),
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
            'Chưa có chuyên khoa nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để thêm chuyên khoa mới.',
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
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const CircleAvatar(radius: 28),
            title: Container(
              height: 16,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 12,
              width: 150,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyCard(Specialty specialty) {
    return Card(
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
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
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
                  } else if (value == 'delete') {
                    _showDeleteDialog(specialty);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Xóa'),
                      ],
                    ),
                  ),
                ],
                icon: Icon(Icons.more_vert, color: context.theme.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}