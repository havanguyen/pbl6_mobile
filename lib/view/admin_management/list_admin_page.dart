import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/model/entities/staff.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:pbl6mobile/view_model/admin_management/admin_management_vm.dart';
import 'package:pbl6mobile/view_model/location_work_management/snackbar_service.dart';

import '../../shared/widgets/widget/staff_delete_confirm.dart';

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
      duration: const Duration(milliseconds: 600), // Giảm thời gian để mượt hơn
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 20.0, // Giảm biên độ slide để nhẹ hơn
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad, // Curve nhẹ hơn
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

  void _loadData({bool forceRefresh = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffVm>().fetchStaffs(forceRefresh: forceRefresh);
    });
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        final provider = context.read<StaffVm>();
        provider.updateFilters(searchQuery: _searchController.text);
        _loadData();
        if (provider.isOffline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tìm kiếm từ dữ liệu offline'),
              duration: Duration(seconds: 2),
              backgroundColor: context.theme.primary.withOpacity(0.8),
            ),
          );
        }
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
                          _loadData(forceRefresh: true);
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
                  if (staffVm.isOffline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lọc từ dữ liệu offline'),
                        duration: Duration(seconds: 2),
                        backgroundColor: context.theme.primary.withOpacity(0.8),
                      ),
                    );
                  }
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
                  if (staffVm.isOffline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lọc từ dữ liệu offline'),
                        duration: Duration(seconds: 2),
                        backgroundColor: context.theme.primary.withOpacity(0.8),
                      ),
                    );
                  }
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
                  if (staffVm.isOffline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lọc từ dữ liệu offline'),
                        duration: Duration(seconds: 2),
                        backgroundColor: context.theme.primary.withOpacity(0.8),
                      ),
                    );
                  }
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
                  if (staffVm.isOffline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sắp xếp từ dữ liệu offline'),
                        duration: Duration(seconds: 2),
                        backgroundColor: context.theme.primary.withOpacity(0.8),
                      ),
                    );
                  }
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
                  if (staffVm.isOffline) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sắp xếp từ dữ liệu offline'),
                        duration: Duration(seconds: 2),
                        backgroundColor: context.theme.primary.withOpacity(0.8),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAdminCard(Staff admin, int index) {
    final animationDelay = index < 10 ? Duration(milliseconds: 300 + (index * 50)) : Duration.zero;

    return AnimatedContainer(
      duration: animationDelay,
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
              _loadData(forceRefresh: true);
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
                          if (admin.isMale != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: admin.isMale != null
                                  ? (admin.isMale! ? Colors.blue.withOpacity(0.1) : Colors.pink.withOpacity(0.1))
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              admin.isMale != null ? (admin.isMale! ? 'Nam' : 'Nữ') : 'Chưa xác định',
                              style: TextStyle(
                                color: admin.isMale != null
                                    ? (admin.isMale! ? Colors.blue : Colors.pink)
                                    : Colors.grey,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              _loadData(forceRefresh: true);
                            }
                          },
                        ),
                      ),
                    ),
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
                  onPressed: () => _loadData(forceRefresh: true),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: context.theme.primaryForeground),
              onPressed: () => _loadData(forceRefresh: true),
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
                if (provider.isLoading && provider.staffs.isEmpty) {
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
                Widget content;
                if (provider.error != null && provider.staffs.isEmpty) {
                  content = _buildAnimatedErrorState(provider);
                } else if (provider.staffs.isEmpty) {
                  content = _buildAnimatedEmptyState();
                } else {
                  content = RefreshIndicator(
                    color: context.theme.primary,
                    backgroundColor: context.theme.bg,
                    onRefresh: () => provider.fetchStaffs(forceRefresh: true),
                    child: ListView.builder(
                      itemCount: provider.staffs.length,
                      itemBuilder: (context, index) {
                        return _buildAnimatedAdminCard(provider.staffs[index], index);
                      },
                    ),
                  );
                }
                if (provider.isOffline) {
                  return Column(
                    children: [
                      MaterialBanner(
                        padding: const EdgeInsets.all(16),
                        content: Text(
                          'Bạn đang offline !',
                          style: TextStyle(
                            color: context.theme.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: context.theme.bg.withOpacity(0.95),
                        leading: Icon(
                          Icons.wifi_off,
                          color: context.theme.primary,
                        ),
                        actions: [SizedBox.shrink()],
                      ),
                      Expanded(child: content),
                    ],
                  );
                }
                return content;
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
}