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
          TextField(
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.theme.border.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.theme.primary,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: context.theme.input,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isOffline
                      ? null
                      : () async {
                          final doctorVm = Provider.of<DoctorVm>(
                            context,
                            listen: false,
                          );
                          await Navigator.pushNamed(
                            context,
                            Routes.createDoctor,
                          );
                          doctorVm.fetchDoctors(forceRefresh: true);
                        },
                  style:
                      ElevatedButton.styleFrom(
                        backgroundColor: context.theme.primary,
                        foregroundColor: context.theme.primaryForeground,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ).copyWith(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>((
                              Set<MaterialState> states,
                            ) {
                              if (states.contains(MaterialState.disabled)) {
                                return context.theme.grey;
                              }
                              return context.theme.primary;
                            }),
                      ),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).translate('create_doctor_account'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: context.theme.input,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.filter_alt_outlined,
                    color: context.theme.primary,
                  ),
                  onPressed: _showFilterSheet,
                ),
              ),
            ],
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
              Text(
                AppLocalizations.of(context).translate('filter_sort'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.theme.textColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).translate('gender_label'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context).translate('all')),
                    selected: doctorVm.isMale == null,
                    onSelected: (selected) {
                      doctorVm.updateGenderFilter(null);
                    },
                    selectedColor: context.theme.primary,
                    labelStyle: TextStyle(
                      color: doctorVm.isMale == null
                          ? context.theme.primaryForeground
                          : context.theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context).translate('male')),
                    selected: doctorVm.isMale == true,
                    onSelected: (selected) {
                      doctorVm.updateGenderFilter(true);
                    },
                    selectedColor: context.theme.primary,
                    labelStyle: TextStyle(
                      color: doctorVm.isMale == true
                          ? context.theme.primaryForeground
                          : context.theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      AppLocalizations.of(context).translate('female'),
                    ),
                    selected: doctorVm.isMale == false,
                    onSelected: (selected) {
                      doctorVm.updateGenderFilter(false);
                    },
                    selectedColor: context.theme.primary,
                    labelStyle: TextStyle(
                      color: doctorVm.isMale == false
                          ? context.theme.primaryForeground
                          : context.theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).translate('sort_by'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  DropdownButton<String>(
                    value: doctorVm.sortBy,
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
                          AppLocalizations.of(context).translate('sort_name'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'email',
                        child: Text(
                          AppLocalizations.of(context).translate('sort_email'),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        doctorVm.updateSortFilter(sortBy: value),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: doctorVm.sortOrder,
                    items: [
                      DropdownMenuItem(
                        value: 'asc',
                        child: Text(
                          AppLocalizations.of(context).translate('ascending'),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'desc',
                        child: Text(
                          AppLocalizations.of(context).translate('descending'),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        doctorVm.updateSortFilter(sortOrder: value),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
              motion: const BehindMotion(),
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
                  backgroundColor: context.theme.blue,
                  foregroundColor: context.theme.white,
                  icon: Icons.edit,
                  label: AppLocalizations.of(context).translate('edit'),
                ),
                SlidableAction(
                  onPressed: (context) => _showDeleteDialog(doctor),
                  backgroundColor: context.theme.destructive,
                  foregroundColor: context.theme.white,
                  icon: Icons.delete,
                  label: AppLocalizations.of(context).translate('delete'),
                ),
              ],
            ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
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
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: context.theme.primary.withOpacity(0.1),
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
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
                              color: context.theme.cardForeground,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor.email,
                        style: TextStyle(
                          color: context.theme.mutedForeground,
                          fontSize: 14,
                        ),
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
