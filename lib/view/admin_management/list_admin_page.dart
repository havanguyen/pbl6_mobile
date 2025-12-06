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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: TextStyle(color: context.theme.textColor),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(
                context,
              ).translate('search_by_name_email'),
              labelStyle: TextStyle(color: context.theme.mutedForeground),
              prefixIcon: Icon(Icons.search, color: context.theme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: context.theme.primary),
                      onPressed: () {
                        _searchController.clear();
                        context.read<StaffVm>().resetFilters();
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
                  key: const Key('btn_add_admin'),
                  onPressed: isOffline
                      ? null
                      : () async {
                          final result = await Navigator.pushNamed(
                            context,
                            Routes.createAdmin,
                          );
                          if (result == true) {
                            context.read<StaffVm>().fetchStaffs(
                              forceRefresh: true,
                            );
                          }
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
                    ).translate('create_admin_account'),
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
    return Consumer<StaffVm>(
      builder: (context, staffVm, child) {
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
                AppLocalizations.of(context).translate('gender'),
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
                    selected: staffVm.isMale == null,
                    onSelected: (selected) {
                      staffVm.updateGenderFilter(null);
                    },
                    selectedColor: context.theme.primary,
                    labelStyle: TextStyle(
                      color: staffVm.isMale == null
                          ? context.theme.primaryForeground
                          : context.theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(AppLocalizations.of(context).translate('male')),
                    selected: staffVm.isMale == true,
                    onSelected: (selected) {
                      staffVm.updateGenderFilter(true);
                    },
                    selectedColor: context.theme.primary,
                    labelStyle: TextStyle(
                      color: staffVm.isMale == true
                          ? context.theme.primaryForeground
                          : context.theme.textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      AppLocalizations.of(context).translate('female'),
                    ),
                    selected: staffVm.isMale == false,
                    onSelected: (selected) {
                      staffVm.updateGenderFilter(false);
                    },
                    selectedColor: context.theme.primary,
                    labelStyle: TextStyle(
                      color: staffVm.isMale == false
                          ? context.theme.primaryForeground
                          : context.theme.textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).translate('sort'),
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  DropdownButton<String>(
                    value: staffVm.sortBy,
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
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: staffVm.sortOrder,
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
                        staffVm.updateSortFilter(sortOrder: value),
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

  Widget _buildAnimatedAdminCard(Staff admin, int index, bool isOffline) {
    return Slidable(
      key: ValueKey('admin_item_${admin.id}'),
      endActionPane: isOffline
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              children: [
                SlidableAction(
                  key: ValueKey('admin_edit_button_${admin.id}'),
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
                  foregroundColor: context.theme.white,
                  icon: Icons.edit,
                  label: AppLocalizations.of(context).translate('edit'),
                ),
                SlidableAction(
                  onPressed: (context) => _showDeleteDialog(admin),
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
          key: Key('btn_edit_admin_$index'),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar_${admin.id}',
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: context.theme.primary.withOpacity(0.1),
                    child: Text(
                      admin.fullName.isNotEmpty
                          ? admin.fullName[0].toUpperCase()
                          : 'A',
                      style: TextStyle(
                        fontSize: 20,
                        color: context.theme.primary,
                        fontWeight: FontWeight.bold,
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
                              color: context.theme.cardForeground,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        admin.email,
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
