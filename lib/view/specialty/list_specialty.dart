import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
      }
    });

    _searchController.addListener(_debounceSearch);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.removeListener(_debounceSearch);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
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
          return Column(
            children: [
              _buildSearchSection(provider.isOffline),
              if (provider.isOffline && provider.error != null)
                Container(
                  width: double.infinity,
                  color: Colors.amber,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              if (provider.isLoading && provider.specialties.isNotEmpty)
                const LinearProgressIndicator(),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (provider.isLoading && provider.specialties.isEmpty) {
                      return _buildShimmerList();
                    }
                    if (provider.specialties.isEmpty) {
                      return const Center(
                          child: Text('Không có chuyên khoa nào'));
                    }
                    return RefreshIndicator(
                      onRefresh: () async => context
                          .read<SpecialtyVm>()
                          .fetchSpecialties(forceRefresh: true),
                      child: ListView.builder(
                        controller: _scrollController,
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
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _buildAnimatedCard(
                                    provider.specialties[index],
                                    provider.isOffline),
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
          );
        },
      ),
    );
  }

  Widget _buildSearchSection(bool isOffline) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Tìm kiếm chuyên khoa',
              prefixIcon: Icon(Icons.search, color: context.theme.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.clear, color: context.theme.primary),
                onPressed: () {
                  _searchController.clear();
                  context.read<SpecialtyVm>().resetFilters();
                },
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isOffline
                ? null
                : () async {
              final result =
              await Navigator.pushNamed(context, Routes.createSpecialty);
              if (result == true) {
                context
                    .read<SpecialtyVm>()
                    .fetchSpecialties(forceRefresh: true);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Thêm chuyên khoa'),
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
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const CircleAvatar(radius: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        width: double.infinity, height: 12.0, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 150, height: 10.0, color: Colors.white),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(Specialty specialty, bool isOffline) {
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
                  context, Routes.updateSpecialty,
                  arguments: specialty.toJson());
              if (result == true) {
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.pushNamed(
                context, Routes.specialtyDetail,
                arguments: specialty.toJson());
            if (result == true) {
              context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'specialty_${specialty.id}',
                  child: CircleAvatar(
                    radius: 24,
                    child: Text(
                      specialty.name.isNotEmpty
                          ? specialty.name[0].toUpperCase()
                          : 'C',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        specialty.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Số phần thông tin: ${specialty.infoSectionsCount}',
                        style: TextStyle(color: context.theme.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}