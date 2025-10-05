import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';

import '../../shared/widgets/widget/staff_delete_confirm.dart';
import '../../view_model/admin_management/admin_management_vm.dart';

class AdminListPage extends StatefulWidget {
  const AdminListPage({super.key});

  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  bool _showFilters = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadData();

    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text);
        _debounceSearch();
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
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffVm>().fetchStaffs();
    });
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<StaffVm>().updateFilters(searchQuery: _searchController.text);
        _loadData(); // Thêm dòng này
      }
    });
  }

  void _showDeleteDialog(Staff staff) {
    final snackbarService = Provider.of<SnackbarService>(context, listen: false);
    final staffVm = Provider.of<StaffVm>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteStaffConfirmationDialog(
        staff: staff.toJson(),
        onDeleteSuccess: () {
          staffVm.fetchStaffs().then((_) {
            if (mounted) {
              setState(() {});
            }
          });
        },
        snackbarService: snackbarService,
        role: 'Admin',
      ),
    );
  }

  Widget _buildAnimatedSearchSection() {
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
            // Search Field
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
                  labelText: 'Tìm kiếm theo tên hoặc email',
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
                      context.read<StaffVm>().updateFilters(searchQuery: '');
                      _loadData();
                    },
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter Toggle Button
            Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: context.theme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CustomButtonBlue(
                      onTap: () async {
                        final result = await Navigator.pushNamed(context, Routes.createAdmin);
                        if (result == true) {
                          print('🔄 Refreshing admin list after create');
                          _loadData();
                        }
                      },
                      text: 'Tạo tài khoản admin',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: context.theme.input,
                    boxShadow: [
                      BoxShadow(
                        color: context.theme.border.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                      color: context.theme.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                  ),
                ),
              ],
            ),

            // Filter Section với animation
            if (_showFilters) ...[
              const SizedBox(height: 16),
              _buildFilterSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final staffVm = context.watch<StaffVm>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: context.theme.input,
        boxShadow: [
          BoxShadow(
            color: context.theme.border.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bộ lọc',
                style: TextStyle(
                  color: context.theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.read<StaffVm>().resetFilters();
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _loadData();
                },
                child: Text(
                  'Đặt lại',
                  style: TextStyle(color: context.theme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gender Filter
          Text(
            'Giới tính',
            style: TextStyle(
              color: context.theme.textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: Text('Tất cả'),
                selected: staffVm.isMale == null,
                onSelected: (selected) {
                  context.read<StaffVm>().updateFilters(isMale: null);
                  _loadData();
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
                label: Text('Nam'),
                selected: staffVm.isMale == true,
                onSelected: (selected) {
                  context.read<StaffVm>().updateFilters(isMale: true);
                  _loadData();
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
                label: Text('Nữ'),
                selected: staffVm.isMale == false,
                onSelected: (selected) {
                  context.read<StaffVm>().updateFilters(isMale: false);
                  _loadData();
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
          const SizedBox(height: 16),

          // Sort Options
          Text(
            'Sắp xếp',
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
                hint: Text('Chọn trường sắp xếp'),
                items: [
                  DropdownMenuItem(value: null, child: Text('Mặc định')),
                  DropdownMenuItem(value: 'createdAt', child: Text('Ngày tạo')),
                  DropdownMenuItem(value: 'fullName', child: Text('Tên')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                ],
                onChanged: (value) {
                  context.read<StaffVm>().updateFilters(sortBy: value);
                  _loadData();
                },
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: staffVm.sortOrder,
                hint: Text('Thứ tự'),
                items: [
                  DropdownMenuItem(value: null, child: Text('Mặc định')),
                  DropdownMenuItem(value: 'asc', child: Text('Tăng dần')),
                  DropdownMenuItem(value: 'desc', child: Text('Giảm dần')),
                ],
                onChanged: (value) {
                  context.read<StaffVm>().updateFilters(sortOrder: value);
                  _loadData();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAdminCard(Staff admin, int index) {
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
          onTap: () async {
            final result = await Navigator.pushNamed(
              context,
              Routes.updateAdmin,
              arguments: admin.toJson(),
            );
            if (result == true) {
              print('🔄 Refreshing admin list after update');
              _loadData();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar với animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.theme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: context.theme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        admin.fullName,
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
                        admin.email,
                        style: TextStyle(
                          color: context.theme.mutedForeground,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          if (admin.phone != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.theme.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                admin.phone!,
                                style: TextStyle(
                                  color: context.theme.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: admin.isMale
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.pink.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              admin.isMale ? 'Nam' : 'Nữ',
                              style: TextStyle(
                                color: admin.isMale ? Colors.blue : Colors.pink,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit Button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: context.theme.primary,
                            size: 20,
                          ),
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              Routes.updateAdmin,
                              arguments: admin.toJson(),
                            );
                            if (result == true) {
                              print('🔄 Refreshing admin list after update');
                              _loadData();
                            }
                          },
                        ),
                      ),
                    ),

                    // Delete Button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: context.theme.destructive,
                            size: 20,
                          ),
                          onPressed: () => _showDeleteDialog(admin),
                        ),
                      ),
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
                  Icons.admin_panel_settings_outlined,
                  size: 64,
                  color: context.theme.mutedForeground,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchQuery.isNotEmpty ? 'Không tìm thấy admin phù hợp' : 'Danh sách admin trống',
                style: TextStyle(
                  color: context.theme.mutedForeground,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Thử tìm kiếm với từ khóa khác hoặc điều chỉnh bộ lọc'
                    : 'Bắt đầu bằng cách tạo tài khoản admin đầu tiên',
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
                    onPressed: () => Navigator.pushNamed(context, Routes.createAdmin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primary,
                      foregroundColor: context.theme.primaryForeground,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Tạo admin đầu tiên',
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

  Widget _buildAnimatedPagination(StaffVm provider) {
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
            // Previous Button
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
                  backgroundColor: provider.hasPrev ? context.theme.primary : context.theme.input,
                  foregroundColor: provider.hasPrev ? context.theme.primaryForeground : context.theme.mutedForeground,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios, size: 16),
                    const SizedBox(width: 4),
                    Text('Trước'),
                  ],
                ),
              ),
            ),

            // Page Info
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

            // Next Button
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
                  backgroundColor: provider.hasNext ? context.theme.primary : context.theme.input,
                  foregroundColor: provider.hasNext ? context.theme.primaryForeground : context.theme.mutedForeground,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Sau'),
                    const SizedBox(width: 4),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        elevation: 0,
        title: Text(
          'Quản lý tài khoản admin',
          style: TextStyle(
            color: context.theme.primaryForeground,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Animated Refresh Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: context.theme.primaryForeground),
              onPressed: _loadData,
            ),
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: Column(
        children: [
          _buildAnimatedSearchSection(),
          Expanded(
            child: Consumer<StaffVm>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
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

                if (provider.error != null) {
                  return _buildAnimatedErrorState(provider);
                }

                if (provider.staffs.isEmpty) {
                  return _buildAnimatedEmptyState();
                }

                return RefreshIndicator(
                  color: context.theme.primary,
                  backgroundColor: context.theme.bg,
                  onRefresh: () => provider.fetchStaffs(),
                  child: ListView.builder(
                    itemCount: provider.staffs.length,
                    itemBuilder: (context, index) {
                      return _buildAnimatedAdminCard(provider.staffs[index], index);
                    },
                  ),
                );
              },
            ),
          ),
          Consumer<StaffVm>(
            builder: (context, provider, child) {
              if (provider.total >= 10) {
                return _buildAnimatedPagination(provider);
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedErrorState(StaffVm provider) {
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
                provider.error!,
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
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