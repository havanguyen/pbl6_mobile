import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/admin_management/admin_management_vm.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../shared/widgets/widget/staff_delete_confirm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';

class AdminListPage extends StatefulWidget {
  const AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StaffVm>().fetchStaffs(forceRefresh: true);
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
      context.read<StaffVm>().loadMore();
    }
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        context.read<StaffVm>().updateSearchQuery(_searchController.text);
      }
    });
  }

  void _showDeleteDialog(Staff staff) {
    final snackbarService = Provider.of<SnackbarService>(
      context,
      listen: false,
    );
    final staffVm = Provider.of<StaffVm>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteStaffConfirmationDialog(
        staff: staff.toJson(),
        onDeleteSuccess: () {
          staffVm.fetchStaffs(forceRefresh: true);
        },
        snackbarService: snackbarService,
        role: 'Admin',
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.theme.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.theme.input),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: context.theme.textColor),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(
                        context,
                      ).translate('search_by_name_email'),
                      hintStyle: TextStyle(
                        color: context.theme.mutedForeground,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: context.theme.mutedForeground,
                        size: 20,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: context.theme.mutedForeground,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                context.read<StaffVm>().resetFilters();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: context.theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: Icon(Icons.tune, color: context.theme.primary),
                  onPressed: _showFilterSheet,
                  tooltip: AppLocalizations.of(context).translate('filter'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('btn_add_admin'),
              onPressed: isOffline
                  ? null
                  : () async {
                      final result = await Navigator.pushNamed(
                        context,
                        Routes.createAdmin,
                      );
                      if (result == true) {
                        context.read<StaffVm>().fetchStaffs(forceRefresh: true);
                      }
                    },
              icon: Icon(
                Icons.person_add_outlined,
                size: 20,
                color: context.theme.primaryForeground,
              ),
              label: Text(
                AppLocalizations.of(context).translate('create_admin_account'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primary,
                    foregroundColor: context.theme.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ).copyWith(
                    backgroundColor: MaterialStateProperty.resolveWith<Color?>((
                      Set<MaterialState> states,
                    ) {
                      if (states.contains(MaterialState.disabled)) {
                        return context.theme.muted;
                      }
                      return context.theme.primary;
                    }),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Consumer<StaffVm>(
      builder: (context, staffVm, child) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: context.theme.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.theme.muted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      staffVm.resetFilters();
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('reset'),
                      style: TextStyle(color: context.theme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).translate('gender'),
                style: TextStyle(
                  color: context.theme.mutedForeground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      label: AppLocalizations.of(context).translate('all'),
                      isSelected: staffVm.isMale == null,
                      onSelected: (_) => staffVm.updateGenderFilter(null),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      label: AppLocalizations.of(context).translate('male'),
                      isSelected: staffVm.isMale == true,
                      onSelected: (_) => staffVm.updateGenderFilter(true),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context,
                      label: AppLocalizations.of(context).translate('female'),
                      isSelected: staffVm.isMale == false,
                      onSelected: (_) => staffVm.updateGenderFilter(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).translate('sort'),
                style: TextStyle(
                  color: context.theme.mutedForeground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
                          value: staffVm.sortBy,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: context.theme.mutedForeground,
                          ),
                          dropdownColor: context.theme.card,
                          style: TextStyle(color: context.theme.textColor),
                          items: [
                            DropdownMenuItem(
                              value: 'createdAt',
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).translate('created_date'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'fullName',
                              child: Text(
                                AppLocalizations.of(context).translate('name'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'email',
                              child: Text(
                                AppLocalizations.of(context).translate('email'),
                              ),
                            ),
                          ],
                          onChanged: (value) =>
                              staffVm.updateSortFilter(sortBy: value),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                          value: staffVm.sortOrder,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: context.theme.mutedForeground,
                          ),
                          dropdownColor: context.theme.card,
                          style: TextStyle(color: context.theme.textColor),
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
                              staffVm.updateSortFilter(sortOrder: value),
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
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: context.theme.bg,
      selectedColor: context.theme.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? context.theme.primary : context.theme.textColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? context.theme.primary.withOpacity(0.5)
              : context.theme.input,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      showCheckmark: false,
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

  Widget _buildAnimatedAdminCard(Staff admin, int index, bool isOffline) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Slidable(
        key: ValueKey('admin_item_${admin.id}'),
        endActionPane: isOffline
            ? null
            : ActionPane(
                motion: const StretchMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) async {
                      final result = await Navigator.pushNamed(
                        context,
                        Routes.updateAdmin,
                        arguments: admin.toJson(),
                      );
                      if (result == true)
                        context.read<StaffVm>().fetchStaffs(forceRefresh: true);
                    },
                    backgroundColor: context.theme.blue,
                    foregroundColor: Colors.white,
                    icon: Icons.edit_outlined,
                    label: AppLocalizations.of(context).translate('edit'),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  SlidableAction(
                    onPressed: (context) => _showDeleteDialog(admin),
                    backgroundColor: context.theme.destructive,
                    foregroundColor: Colors.white,
                    icon: Icons.delete_outline,
                    label: AppLocalizations.of(context).translate('delete'),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                ],
              ),
        child: Container(
          decoration: BoxDecoration(
            color: context.theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.theme.input.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: isOffline
                ? null
                : () async {
                    final result = await Navigator.pushNamed(
                      context,
                      Routes.updateAdmin,
                      arguments: admin.toJson(),
                    );
                    if (result == true)
                      context.read<StaffVm>().fetchStaffs(forceRefresh: true);
                  },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Hero(
                    tag: 'avatar_${admin.id}',
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.theme.primary.withOpacity(0.2),
                            context.theme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.theme.primary.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          admin.fullName.isNotEmpty
                              ? admin.fullName[0].toUpperCase()
                              : 'A',
                          style: TextStyle(
                            fontSize: 22,
                            color: context.theme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: 'name_${admin.id}',
                          child: Material(
                            color: Colors.transparent,
                            child: Text(
                              admin.fullName,
                              style: TextStyle(
                                color: context.theme.textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
                                admin.email,
                                style: TextStyle(
                                  color: context.theme.mutedForeground,
                                  fontSize: 14,
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
                    Icons.chevron_right,
                    color: context.theme.mutedForeground.withOpacity(0.5),
                  ),
                ],
              ),
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
        title: Text(
          AppLocalizations.of(context).translate('admin_management_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: context.theme.white),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.white),
            onPressed: () =>
                context.read<StaffVm>().fetchStaffs(forceRefresh: true),
          ),
        ],
      ),
      body: Consumer<StaffVm>(
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
              if (provider.isLoading && provider.staffs.isNotEmpty)
                const LinearProgressIndicator(),
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (provider.isLoading && provider.staffs.isEmpty) {
                      return _buildShimmerList();
                    }

                    if (provider.staffs.isEmpty) {
                      return Center(
                        child: Text(
                          AppLocalizations.of(
                            context,
                          ).translate('no_admins_found'),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => context
                          .read<StaffVm>()
                          .fetchStaffs(forceRefresh: true),
                      child: ListView.builder(
                        key: const ValueKey('admin_list_scroll_view'),
                        controller: _scrollController,
                        itemCount:
                            provider.staffs.length +
                            (provider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == provider.staffs.length) {
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
                                child: _buildAnimatedAdminCard(
                                  provider.staffs[index],
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
