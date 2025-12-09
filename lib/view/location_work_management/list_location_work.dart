import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../model/entities/work_location.dart';
import '../../shared/extensions/custome_theme_extension.dart';
import '../../shared/localization/app_localizations.dart';
import '../../shared/routes/routes.dart';
import '../../shared/widgets/widget/delete_cofirm.dart';
import '../../view_model/location_work_management/location_work_vm.dart';
import '../../view_model/location_work_management/snackbar_service.dart';

class LocationWorkListPage extends StatefulWidget {
  const LocationWorkListPage({super.key});

  @override
  State<LocationWorkListPage> createState() => _LocationWorkListPageState();
}

class _LocationWorkListPageState extends State<LocationWorkListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LocationWorkVm>().fetchLocations(forceRefresh: true);
      }
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {}); // Trigger rebuild to filter list locally
      }
    });
  }

  void _showDeleteDialog(WorkLocation location) {
    if (context.read<LocationWorkVm>().isOffline) return;

    final snackbarService = Provider.of<SnackbarService>(
      context,
      listen: false,
    );
    final locationWorkVm = Provider.of<LocationWorkVm>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteConfirmationDialog(
        location: location,
        onDeleteSuccess: () async {
          locationWorkVm.fetchLocations(forceRefresh: true);
        },
        snackbarService: snackbarService,
      ),
    );
  }

  Future<void> _toggleIsActive(WorkLocation location) async {
    if (context.read<LocationWorkVm>().isOffline) return;

    final bool currentActive = location.isActive;
    final newIsActive = !currentActive;
    final success = await Provider.of<LocationWorkVm>(
      context,
      listen: false,
    ).updateLocationIsActive(location.id, newIsActive);

    if (mounted) {
      final snackbarService = Provider.of<SnackbarService>(
        context,
        listen: false,
      );
      if (success) {
        snackbarService.showSuccess(
          AppLocalizations.of(context).translate('update_status_success'),
        );
      } else {
        snackbarService.showError(
          AppLocalizations.of(context).translate('update_status_failed'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocationWorkVm>();

    // Listen to global SnackbarService
    final snackbarService = context.watch<SnackbarService>();
    if (snackbarService.message != null) {
      // Use Future.microtask to avoid build conflicts
      Future.microtask(() {
        if (mounted && snackbarService.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                snackbarService.message!,
                style: TextStyle(
                  color: snackbarService.isError
                      ? context.theme.destructiveForeground
                      : context.theme.primaryForeground,
                ),
              ),
              backgroundColor: snackbarService.isError
                  ? context.theme.destructive
                  : context.theme.green,
            ),
          );
          snackbarService.clear();
        }
      });
    }

    return Scaffold(
      backgroundColor: context.theme.bg,
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        title: Text(
          AppLocalizations.of(context).translate('location_management_title'),
          style: TextStyle(
            color: context.theme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.white),
            onPressed: vm.isLoading
                ? null
                : () => vm.fetchLocations(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(vm.isOffline),
          if (vm.isOffline && vm.error != null)
            Container(
              width: double.infinity,
              color: context.theme.yellow,
              padding: const EdgeInsets.all(8.0),
              child: Text(
                AppLocalizations.of(context).translate(vm.error!),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.theme.popover),
              ),
            ),
          if (vm.isLoading && vm.locations.isEmpty)
            const LinearProgressIndicator(),
          Expanded(
            child: Builder(
              builder: (context) {
                if (vm.isLoading && vm.locations.isEmpty) {
                  return _buildShimmerList();
                }

                // Filter locally for now effectively client-side search
                final query = _searchController.text.toLowerCase();
                final filteredLocations = vm.locations.where((loc) {
                  final name = loc.name.toLowerCase();
                  final address = loc.address?.toLowerCase() ?? '';
                  return name.contains(query) || address.contains(query);
                }).toList();

                if (vm.error != null && vm.locations.isEmpty && !vm.isOffline) {
                  return _buildErrorState(vm);
                }

                if (filteredLocations.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: context.theme.primary,
                  backgroundColor: context.theme.bg,
                  onRefresh: () async => vm.fetchLocations(forceRefresh: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount:
                        filteredLocations.length +
                        (vm.total > 10
                            ? 1
                            : 0), // +1 for pagination if implemented or spacer
                    itemBuilder: (context, index) {
                      if (index == filteredLocations.length) {
                        // Pagination controls can go here if needed, or just bottom padding
                        return (vm.total >= 10 && !vm.isOffline)
                            ? _buildPaginationControls(vm)
                            : const SizedBox(height: 80);
                      }

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildLocationCard(
                              filteredLocations[index],
                              vm.isOffline,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: vm.isOffline
            ? context.theme.grey
            : context.theme.primary,
        onPressed: vm.isOffline
            ? null
            : () async {
                final result = await Navigator.pushNamed(
                  context,
                  Routes.createLocationWork,
                );
                if (result == true && mounted) {
                  vm.fetchLocations(forceRefresh: true);
                }
              },
        child: Icon(Icons.add, color: context.theme.primaryForeground),
      ),
    );
  }

  Widget _buildSearchSection(bool isOffline) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: context.theme.textColor),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(
            context,
          ).translate('search_location_hint'),
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
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: context.theme.border.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.theme.primary, width: 1.5),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: context.theme.mutedForeground),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildLocationCard(WorkLocation location, bool isOffline) {
    bool isActive = location.isActive;

    return Slidable(
      key: ValueKey(location.id),
      endActionPane: isOffline
          ? null
          : ActionPane(
              motion: const BehindMotion(),
              children: [
                SlidableAction(
                  onPressed: (context) async {
                    final result = await Navigator.pushNamed(
                      context,
                      Routes.updateLocationWork,
                      arguments: location,
                    );
                    if (result == true && mounted) {
                      context.read<LocationWorkVm>().fetchLocations(
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
                  onPressed: (context) => _showDeleteDialog(location),
                  backgroundColor: context.theme.destructive,
                  foregroundColor: context.theme.destructiveForeground,
                  icon: Icons.delete,
                  label: AppLocalizations.of(context).translate('delete'),
                ),
              ],
            ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: context.theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.theme.border.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isOffline
              ? null // Or show snackbar
              : () async {
                  // Navigate to details if exists, or edit
                  final result = await Navigator.pushNamed(
                    context,
                    Routes.updateLocationWork,
                    arguments: location,
                  );
                  if (result == true && mounted) {
                    context.read<LocationWorkVm>().fetchLocations(
                      forceRefresh: true,
                    );
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? context.theme.green.withOpacity(0.1)
                        : context.theme.destructive.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: isActive
                        ? context.theme.green
                        : context.theme.destructive,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.theme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.address ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.theme.mutedForeground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location.phone != null &&
                          location.phone!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: context.theme.mutedForeground,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location.phone!,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.theme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Toggle Switch
                Switch(
                  value: isActive,
                  activeColor: context.theme.green,
                  onChanged: isOffline
                      ? null
                      : (_) => _toggleIsActive(location),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 80,
            color: context.theme.mutedForeground,
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty
                ? AppLocalizations.of(context).translate('no_locations_yet')
                : AppLocalizations.of(context).translate('no_locations_found'),
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
                  ).translate('add_first_location_hint')
                : AppLocalizations.of(context).translate('try_search_again'),
            style: TextStyle(color: context.theme.mutedForeground),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(LocationWorkVm vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: context.theme.destructive),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('error_occurred'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vm.error ?? 'Unknown error',
            style: TextStyle(color: context.theme.mutedForeground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => vm.fetchLocations(forceRefresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primary,
              foregroundColor: context.theme.primaryForeground,
            ),
            child: Text(AppLocalizations.of(context).translate('retry')),
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
          child: ListTile(
            leading: const CircleAvatar(radius: 24),
            title: Container(height: 16, width: 150, color: Colors.white),
            subtitle: Container(height: 12, width: 100, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls(LocationWorkVm provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: provider.hasPrev ? () => provider.prevPage() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.hasPrev
                  ? context.theme.primary
                  : context.theme.muted,
              foregroundColor: provider.hasPrev
                  ? context.theme.primaryForeground
                  : context.theme.mutedForeground,
            ),
            child: const Icon(Icons.arrow_back_ios, size: 16),
          ),
          Text(
            '${provider.currentPage} / ${provider.totalPages}',
            style: TextStyle(
              color: context.theme.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          ElevatedButton(
            onPressed: provider.hasNext ? () => provider.nextPage() : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: provider.hasNext
                  ? context.theme.primary
                  : context.theme.muted,
              foregroundColor: provider.hasNext
                  ? context.theme.primaryForeground
                  : context.theme.mutedForeground,
            ),
            child: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
}
