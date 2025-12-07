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
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

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
    final snackbarService = Provider.of<SnackbarService>(
      context,
      listen: false,
    );
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
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('specialty_management_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.theme.appBar,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.white),
            onPressed: specialtyVm.isLoading
                ? null
                : () => specialtyVm.fetchSpecialties(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndActions(specialtyVm.isOffline),
          if (specialtyVm.isOffline && specialtyVm.error != null)
            Container(
              width: double.infinity,
              color: context.theme.yellow,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                specialtyVm.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.theme.popover),
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
                  return Center(
                    child: Text(
                      '${AppLocalizations.of(context).translate('error_occurred')} ${specialtyVm.error}',
                    ),
                  );
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
                    itemCount:
                        specialtyVm.specialties.length +
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
                              specialty,
                              specialtyVm.isOffline,
                            ),
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
              hintText: AppLocalizations.of(
                context,
              ).translate('search_specialty_hint'),
              hintStyle: TextStyle(
                color: context.theme.mutedForeground.withOpacity(0.7),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: context.theme.primary,
                size: 20,
              ),
              filled: true,
              fillColor: context.theme.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: context.theme.border.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: context.theme.primary,
                  width: 1.5,
                ),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: context.theme.mutedForeground,
                        size: 20,
                      ),
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
                    final result = await Navigator.pushNamed(
                      context,
                      Routes.createSpecialty,
                    );
                    if (result == true && mounted) {
                      context.read<SpecialtyVm>().fetchSpecialties(
                        forceRefresh: true,
                      );
                    }
                  },
            icon: const Icon(Icons.add),
            label: Text(
              AppLocalizations.of(context).translate('create_specialty_title'),
            ),
            style:
                ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primary,
                  foregroundColor: context.theme.primaryForeground,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).copyWith(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                    Set<MaterialState> states,
                  ) {
                    if (states.contains(MaterialState.disabled)) {
                      return context.theme.grey;
                    }
                    return context.theme.primary;
                  }),
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
                ? AppLocalizations.of(context).translate('no_specialties_yet')
                : AppLocalizations.of(
                    context,
                  ).translate('no_specialties_found'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? AppLocalizations.of(
                    context,
                  ).translate('add_new_specialty_hint')
                : AppLocalizations.of(context).translate('try_search_again'),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: context.theme.white,
            ),
            title: const SizedBox(height: 16, width: 150),
            subtitle: const SizedBox(height: 12, width: 100),
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
                      context.read<SpecialtyVm>().fetchSpecialties(
                        forceRefresh: true,
                      );
                    }
                  },
                  backgroundColor: context.theme.blue,
                  foregroundColor: context.theme.white,
                  icon: Icons.edit,
                  label: AppLocalizations.of(context).translate('edit'),
                ),
                SlidableAction(
                  onPressed: (context) => _showDeleteDialog(specialty),
                  backgroundColor: context.theme.destructive,
                  foregroundColor: context.theme.white,
                  icon: Icons.delete,
                  label: AppLocalizations.of(context).translate('delete'),
                ),
              ],
            ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: context.theme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: context.theme.border.withOpacity(0.5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final result = await Navigator.pushNamed(
              context,
              Routes.specialtyDetail,
              arguments: specialty,
            );
            if (result == true && mounted) {
              context.read<SpecialtyVm>().fetchSpecialties(forceRefresh: true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.theme.primary.withOpacity(0.1),
                        context.theme.primary.withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.medical_services_rounded,
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
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.theme.bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.theme.border.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '${AppLocalizations.of(context).translate('info_section_count')}: ${specialty.infoSectionsCount}',
                          style: TextStyle(
                            color: context.theme.mutedForeground,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: context.theme.mutedForeground.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
