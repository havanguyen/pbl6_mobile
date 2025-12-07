import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/doctor.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

import '../../shared/widgets/widget/doctor_delete_confirm.dart';
import '../../view_model/admin_management/doctor_management_vm.dart';
import '../../view_model/location_work_management/snackbar_service.dart';

class DoctorListPage extends StatefulWidget {
  const DoctorListPage({super.key});

  @override
  State<DoctorListPage> createState() => _DoctorListPageState();
}

class _DoctorListPageState extends State<DoctorListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DoctorVm>().fetchDoctors(forceRefresh: true);
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
      context.read<DoctorVm>().loadMore();
    }
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        context.read<DoctorVm>().updateSearchQuery(_searchController.text);
      }
    });
  }

  void _showDeleteDialog(Doctor doctor) {
    final snackbarService = Provider.of<SnackbarService>(
      context,
      listen: false,
    );
    final doctorVm = Provider.of<DoctorVm>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteDoctorConfirmationDialog(
        doctor: doctor.toJson(),
        onDeleteSuccess: () {
          doctorVm.fetchDoctors(forceRefresh: true);
        },
        snackbarService: snackbarService,
        role: AppLocalizations.of(context).translate('doctor_role'),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.theme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSection(),
    );
  }

  Widget _buildSearchSection(bool isOffline) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.theme.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.theme.input, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: context.theme.textColor),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      ).translate('search_doctor_hint'),
                      hintStyle: TextStyle(
                        color: context.theme.mutedForeground.withOpacity(0.7),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: context.theme.primary,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
                                context.read<DoctorVm>().resetFilters();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: context.theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.theme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.filter_list_rounded,
                      color: context.theme.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isOffline)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final doctorVm = Provider.of<DoctorVm>(
                    context,
                    listen: false,
                  );
                  await Navigator.pushNamed(context, Routes.createDoctor);
                  doctorVm.fetchDoctors(forceRefresh: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.theme.primary,
                  foregroundColor: context.theme.primaryForeground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: Text(
                  AppLocalizations.of(
                    context,
                  ).translate('create_doctor_account'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Consumer<DoctorVm>(
      builder: (context, doctorVm, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: context.theme.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('filter_sort'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.theme.textColor,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: context.theme.mutedForeground,
                    ),
                    label: Text(
                      AppLocalizations.of(context).translate('reset'),
                      style: TextStyle(color: context.theme.mutedForeground),
                    ),
                    onPressed: () {
                      doctorVm.resetFilters();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).translate('gender_label'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: AppLocalizations.of(context).translate('all'),
                    isSelected: doctorVm.isMale == null,
                    onSelected: () => doctorVm.updateGenderFilter(null),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: AppLocalizations.of(context).translate('male'),
                    isSelected: doctorVm.isMale == true,
                    onSelected: () => doctorVm.updateGenderFilter(true),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: AppLocalizations.of(context).translate('female'),
                    isSelected: doctorVm.isMale == false,
                    onSelected: () => doctorVm.updateGenderFilter(false),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).translate('sort_by'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.theme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.theme.input),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: doctorVm.sortBy,
                          dropdownColor: context.theme.card,
                          style: TextStyle(color: context.theme.textColor),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: context.theme.mutedForeground,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'createdAt',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('sort_created_at'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'fullName',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('sort_name'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'email',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('sort_email'),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              doctorVm.updateSortFilter(sortBy: value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: context.theme.bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.theme.input),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: doctorVm.sortOrder,
                          dropdownColor: context.theme.card,
                          style: TextStyle(color: context.theme.textColor),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: context.theme.mutedForeground,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'asc',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('ascending'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'desc',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('descending'),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              doctorVm.updateSortFilter(sortOrder: value),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.theme.primary : context.theme.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.theme.primary : context.theme.input,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? context.theme.primaryForeground
                : context.theme.textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: context.theme.white,
                  shape: BoxShape.circle,
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 12.0,
                      color: context.theme.white,
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
                    Container(
                      width: double.infinity,
                      height: 10.0,
                      color: context.theme.white,
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 2.0)),
                    Container(
                      width: 100.0,
                      height: 8.0,
                      color: context.theme.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDoctorCard(Doctor doctor, int index, bool isOffline) {
    final String? avatarUrl = (doctor as dynamic).avatarUrl;

    return Slidable(
      key: ValueKey(doctor.id),
      endActionPane: isOffline
          ? null
          : ActionPane(
              motion: const StretchMotion(),
              extentRatio: 0.5,
              children: [
                SlidableAction(
                  onPressed: (context) async {
                    final doctorVm = Provider.of<DoctorVm>(
                      context,
                      listen: false,
                    );
                    await Navigator.pushNamed(
                      context,
                      Routes.updateDoctor,
                      arguments: doctor.toJson(),
                    );
                    doctorVm.fetchDoctors(forceRefresh: true);
                  },
                  backgroundColor: context.theme.primary,
                  foregroundColor: context.theme.white,
                  icon: Icons.edit_outlined,
                  label: AppLocalizations.of(context).translate('edit'),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
                SlidableAction(
                  onPressed: (context) => _showDeleteDialog(doctor),
                  backgroundColor: context.theme.destructive,
                  foregroundColor: context.theme.white,
                  icon: Icons.delete_outline_rounded,
                  label: AppLocalizations.of(context).translate('delete'),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.theme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.input.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isOffline
              ? null
              : () {
                  Navigator.pushNamed(
                    context,
                    Routes.doctorDetail,
                    arguments: doctor.id,
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar_${doctor.id}',
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.theme.primary.withOpacity(0.2),
                        width: 2,
                      ),
                      image: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(avatarUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Text(
                            doctor.fullName.isNotEmpty
                                ? doctor.fullName[0].toUpperCase()
                                : 'D',
                            style: TextStyle(
                              fontSize: 20,
                              color: context.theme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'name_${doctor.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Text(
                            doctor.fullName,
                            style: TextStyle(
                              color: context.theme.textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: context.theme.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor.email,
                              style: TextStyle(
                                color: context.theme.mutedForeground,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: context.theme.mutedForeground.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).translate('doctor_management_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.white),
            onPressed: () =>
                context.read<DoctorVm>().fetchDoctors(forceRefresh: true),
          ),
        ],
      ),
      body: Consumer<DoctorVm>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildSearchSection(provider.isOffline),
              if (provider.isOffline && provider.error != null)
                Container(
                  width: double.infinity,
                  color: context.theme.yellow,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.theme.popover),
                  ),
                ),
              if (provider.isLoading && provider.doctors.isNotEmpty)
                const LinearProgressIndicator(),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (provider.isLoading && provider.doctors.isEmpty) {
                      return _buildShimmerList();
                    }

                    if (provider.doctors.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).translate('no_doctors_found'),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => context
                          .read<DoctorVm>()
                          .fetchDoctors(forceRefresh: true),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount:
                            provider.doctors.length +
                            (provider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.doctors.length) {
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
                                child: _buildAnimatedDoctorCard(
                                  provider.doctors[index],
                                  index,
                                  provider.isOffline,
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
          );
        },
      ),
    );
  }
}
