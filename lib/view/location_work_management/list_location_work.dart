import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';
import 'package:provider/provider.dart';

import '../../model/services/remote/work_location_service.dart';
import '../../view_model/location_work_management/location_work_vm.dart';

class LocationWorkListPage extends StatefulWidget {
  const LocationWorkListPage({super.key});

  @override
  State<LocationWorkListPage> createState() => _LocationWorkListPageState();
}

class _LocationWorkListPageState extends State<LocationWorkListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationWorkVm>(context, listen: false).fetchLocations();
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void _showDeleteDialog(dynamic location) {
    final TextEditingController passwordController = TextEditingController();
    bool isDeleting = false; // trạng thái loading

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: context.theme.popover,
              title: Text(
                'Xác nhận xóa',
                style: TextStyle(color: context.theme.popoverForeground),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bạn có chắc chắn muốn xóa địa điểm: ${location['name']}?',
                    style: TextStyle(color: context.theme.popoverForeground),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    style: TextStyle(color: context.theme.textColor),
                    decoration: InputDecoration(
                      labelText: 'Nhập mật khẩu Admin/Super Admin',
                      labelStyle: TextStyle(color: context.theme.mutedForeground),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: context.theme.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: context.theme.ring),
                      ),
                      filled: true,
                      fillColor: context.theme.input,
                    ),
                    onSubmitted: (_) async {
                      setState(() => isDeleting = true);
                      await _confirmDelete(location, passwordController.text);
                      setState(() => isDeleting = false);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: Text('Hủy', style: TextStyle(color: context.theme.mutedForeground)),
                ),
                isDeleting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : TextButton(
                  onPressed: () async {
                    setState(() => isDeleting = true);
                    await _confirmDelete(location, passwordController.text);
                    setState(() => isDeleting = false);
                  },
                  child: Text('Xóa', style: TextStyle(color: context.theme.destructive)),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => passwordController.dispose());
  }

  Future<void> _confirmDelete(dynamic location, String password) async {
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng nhập mật khẩu để xác nhận xóa.',
            style: TextStyle(color: context.theme.destructiveForeground),
          ),
          backgroundColor: context.theme.destructive,
        ),
      );
      return;
    }

    final success = await LocationWorkService.deleteLocation(location['id'], password: password);

    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa địa điểm thành công!', style: TextStyle(color: context.theme.primaryForeground)),
          backgroundColor: context.theme.green,
        ),
      );
      Provider.of<LocationWorkVm>(context, listen: false).fetchLocations();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Xóa thất bại. Kiểm tra mật khẩu hoặc thử lại.',
            style: TextStyle(color: context.theme.destructiveForeground),
          ),
          backgroundColor: context.theme.destructive,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.appBar,
        title: Text(
          'Quản lý địa điểm làm việc',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.primaryForeground),
            onPressed: () => Provider.of<LocationWorkVm>(context, listen: false).fetchLocations(),
          ),
        ],
      ),
      backgroundColor: context.theme.bg,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.theme.textColor),
                  decoration: InputDecoration(
                    labelText: 'Tìm kiếm theo tên hoặc địa chỉ',
                    labelStyle: TextStyle(color: context.theme.mutedForeground),
                    prefixIcon: Icon(Icons.search, color: context.theme.primary),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.theme.ring),
                    ),
                    filled: true,
                    fillColor: context.theme.input,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: context.theme.primary),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButtonBlue(
                  onTap: () => Navigator.pushNamed(context, Routes.createLocationWork),
                  text: 'Thêm địa điểm làm việc',
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<LocationWorkVm>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return Center(child: CircularProgressIndicator(color: context.theme.primary));
                }
                if (provider.error != null) {
                  return Center(child: Text(provider.error!, style: TextStyle(color: context.theme.destructive)));
                }

                final filteredLocations = provider.locations.where((loc) {
                  final name = loc['name']?.toLowerCase() ?? '';
                  final address = loc['address']?.toLowerCase() ?? '';
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) || address.contains(query);
                }).toList();

                if (filteredLocations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 64, color: context.theme.mutedForeground),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'Chưa có địa điểm nào' : 'Không tìm thấy địa điểm phù hợp',
                          style: TextStyle(color: context.theme.mutedForeground),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = filteredLocations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: context.theme.card,
                      child: ListTile(
                        textColor: context.theme.cardForeground,
                        leading: CircleAvatar(
                          backgroundColor: context.theme.primary,
                          child: Text(
                            location['name']?[0].toUpperCase() ?? 'L',
                            style: TextStyle(color: context.theme.primaryForeground),
                          ),
                        ),
                        title: Text(
                          location['name'] ?? 'N/A',
                          style: TextStyle(color: context.theme.cardForeground),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(location['address'] ?? 'N/A', style: TextStyle(color: context.theme.mutedForeground)),
                            Text('SĐT: ${location['phone'] ?? 'N/A'}', style: TextStyle(color: context.theme.mutedForeground)),
                            Text('Múi giờ: ${location['timezone'] ?? 'N/A'}', style: TextStyle(color: context.theme.mutedForeground)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: context.theme.primary),
                              onPressed: () => Navigator.pushNamed(
                                context,
                                Routes.updateLocationWork,
                                arguments: location,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: context.theme.destructive),
                              onPressed: () => _showDeleteDialog(location),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}