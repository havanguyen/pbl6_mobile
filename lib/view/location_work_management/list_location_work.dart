import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:provider/provider.dart';
import '../../model/entities/work_location.dart';
import '../../view_model/location_work_management/location_work_vm.dart';
import '../../shared/widgets/widget/delete_cofirm.dart';
import '../../view_model/location_work_management/snackbar_service.dart';

class LocationWorkListPage extends StatefulWidget {
  const LocationWorkListPage({super.key});

  @override
  State<LocationWorkListPage> createState() => _LocationWorkListPageState();
}

class _LocationWorkListPageState extends State<LocationWorkListPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();

    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text);
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationWorkVm>(context, listen: false)
          .fetchLocations(forceRefresh: true);
    });
  }

  void _showDeleteDialog(WorkLocation location) {
    final snackbarService =
    Provider.of<SnackbarService>(context, listen: false);
    final locationWorkVm =
    Provider.of<LocationWorkVm>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteConfirmationDialog(
        location: location,
        onDeleteSuccess: () {
          locationWorkVm.fetchLocations().then((_) {
            if (mounted) {
              setState(() {});
            }
          });
        },
        snackbarService: snackbarService,
      ),
    );
  }

  Future<void> _toggleIsActive(WorkLocation location) async {
    final bool currentActive = location.isActive;
    final newIsActive = !currentActive;
    final success = await Provider.of<LocationWorkVm>(context, listen: false)
        .updateLocationIsActive(location.id, newIsActive);

    if (success && mounted) {
      final snackbarService =
      Provider.of<SnackbarService>(context, listen: false);
      snackbarService.showSuccess('Cập nhật trạng thái thành công!');
    } else if (mounted) {
      final snackbarService =
      Provider.of<SnackbarService>(context, listen: false);
      snackbarService.showError('Cập nhật trạng thái thất bại.');
    }
  }

  Widget _buildAnimatedSearchSection(bool isOffline) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: context.theme.border.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Tìm kiếm theo tên hoặc địa chỉ',
                  labelStyle: TextStyle(
                    color: context.theme.mutedForeground,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.theme.primary,
                    size: 20,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.theme.border),
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
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: context.theme.primary,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: context.theme.primary.withOpacity(0.3),
                    blurRadius: _searchQuery.isEmpty ? 8 : 4,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CustomButtonBlue(
                onTap: isOffline
                    ? () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể thêm khi đang offline'),
                    ),
                  );
                }
                    : () async {
                  final result = await Navigator.pushNamed(
                      context, Routes.createLocationWork);
                  if (result == true) {
                    _loadData();
                  }
                },
                text: 'Thêm địa điểm làm việc',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLocationCard(
      WorkLocation location, int index, bool isOffline) {
    final bool activeStatus = location.isActive;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (index * 100)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: context.theme.border.withOpacity(0.2),
            width: 1,
          ),
        ),
        color: context.theme.card,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isOffline
              ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Không thể chỉnh sửa khi đang offline')),
            );
          }
              : () async {
            final result = await Navigator.pushNamed(
              context,
              Routes.updateLocationWork,
              arguments: location,
            );
            if (result == true) {
              _loadData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: activeStatus
                        ? context.theme.green.withOpacity(0.1)
                        : context.theme.destructive.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: activeStatus
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
                          color: context.theme.cardForeground,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location.address,
                        style: TextStyle(
                          color: context.theme.mutedForeground,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: activeStatus
                              ? context.theme.green.withOpacity(0.1)
                              : context.theme.destructive.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          activeStatus ? '🟢 Hoạt động' : '🔴 Không hoạt động',
                          style: TextStyle(
                            color: activeStatus
                                ? context.theme.green
                                : context.theme.destructive,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: isOffline
                            ? context.theme.mutedForeground
                            : context.theme.destructive,
                        size: 20,
                      ),
                      onPressed: isOffline
                          ? null
                          : () => _showDeleteDialog(location),
                    ),
                    IconButton(
                      icon: Icon(
                        activeStatus ? Icons.toggle_on : Icons.toggle_off,
                        color: isOffline
                            ? context.theme.mutedForeground
                            : (activeStatus
                            ? context.theme.green
                            : context.theme.mutedForeground),
                        size: 32,
                      ),
                      onPressed:
                      isOffline ? null : () => _toggleIsActive(location),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedEmptyState() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.5),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.theme.input,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_off,
                  size: 64,
                  color: context.theme.mutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isEmpty
                    ? 'Chưa có địa điểm nào'
                    : 'Không tìm thấy địa điểm phù hợp',
                style: TextStyle(
                  color: context.theme.mutedForeground,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isEmpty
                    ? 'Bắt đầu bằng cách thêm địa điểm làm việc đầu tiên'
                    : 'Thử tìm kiếm với từ khóa khác',
                style: TextStyle(
                  color: context.theme.mutedForeground.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 24),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: context.theme.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                        context, Routes.createLocationWork)
                        .then((_) => _loadData()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primary,
                      foregroundColor: context.theme.primaryForeground,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Thêm địa điểm đầu tiên',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedPagination(LocationWorkVm provider) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: context.theme.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.theme.border.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: provider.hasPrev
                    ? [
                  BoxShadow(
                    color: context.theme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: provider.hasPrev ? () => provider.prevPage() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.hasPrev
                      ? context.theme.primary
                      : context.theme.input,
                  foregroundColor: provider.hasPrev
                      ? context.theme.primaryForeground
                      : context.theme.mutedForeground,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios, size: 16),
                    SizedBox(width: 4),
                    Text('Trước'),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.theme.input,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Trang ${provider.currentPage} / ${provider.totalPages}',
                style: TextStyle(
                  color: context.theme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: provider.hasNext
                    ? [
                  BoxShadow(
                    color: context.theme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                    : [],
              ),
              child: ElevatedButton(
                onPressed: provider.hasNext ? () => provider.nextPage() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.hasNext
                      ? context.theme.primary
                      : context.theme.input,
                  foregroundColor: provider.hasNext
                      ? context.theme.primaryForeground
                      : context.theme.mutedForeground,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sau'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SnackbarService>(
      builder: (context, snackbarService, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (snackbarService.message != null && mounted) {
            final message = snackbarService.message!;
            final isError = snackbarService.isError;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: TextStyle(
                    color: isError
                        ? context.theme.destructiveForeground
                        : context.theme.primaryForeground,
                  ),
                ),
                backgroundColor:
                isError ? context.theme.destructive : context.theme.green,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );

            snackbarService.clear();
          }
        });

        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.theme.appBar,
            elevation: 0,
            title: Text(
              'Quản lý địa điểm làm việc',
              style: TextStyle(
                color: context.theme.primaryForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: context.theme.primaryForeground),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.refresh,
                      color: context.theme.primaryForeground),
                  onPressed: _loadData,
                ),
              ),
            ],
          ),
          backgroundColor: context.theme.bg,
          body: Consumer<LocationWorkVm>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  _buildAnimatedSearchSection(provider.isOffline),
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
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (provider.isLoading && provider.locations.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: context.theme.primary,
                                  strokeWidth: 2,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Đang tải dữ liệu...',
                                  style: TextStyle(
                                    color: context.theme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (provider.error != null && !provider.isOffline) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              final snackbarService =
                              Provider.of<SnackbarService>(context,
                                  listen: false);
                              if (provider.error!
                                  .contains('ThrottlerException')) {
                                snackbarService.showError(
                                    'Quá nhiều yêu cầu. Vui lòng thử lại sau!');
                              } else {
                                snackbarService.showError(provider.error!);
                              }
                              provider.clearError();
                            }
                          });

                          return _buildAnimatedErrorState(provider);
                        }

                        final filteredLocations =
                        provider.locations.where((loc) {
                          final name = loc.name.toLowerCase();
                          final address = loc.address.toLowerCase();
                          final query = _searchQuery.toLowerCase();
                          return name.contains(query) || address.contains(query);
                        }).toList();

                        if (filteredLocations.isEmpty) {
                          return _buildAnimatedEmptyState();
                        }

                        return RefreshIndicator(
                          color: context.theme.primary,
                          backgroundColor: context.theme.bg,
                          onRefresh: () =>
                              Provider.of<LocationWorkVm>(context,
                                  listen: false)
                                  .fetchLocations(forceRefresh: true),
                          child: ListView.builder(
                            itemCount: filteredLocations.length,
                            itemBuilder: (context, index) {
                              return _buildAnimatedLocationCard(
                                  filteredLocations[index],
                                  index,
                                  provider.isOffline);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  if (provider.total >= 10 && !provider.isOffline)
                    _buildAnimatedPagination(provider),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAnimatedErrorState(LocationWorkVm provider) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 0.5),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.theme.destructive.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: context.theme.destructive,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Đã xảy ra lỗi',
                style: TextStyle(
                  color: context.theme.destructive,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error ?? 'Lỗi không xác định',
                style: TextStyle(
                  color: context.theme.mutedForeground,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.primary.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primary,
                    foregroundColor: context.theme.primaryForeground,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}