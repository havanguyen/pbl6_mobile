// lib/features/specialty/list_specialty.dart
import 'package:flutter/material.dart';
import 'package:pbl6mobile/view_model/specialty/specialty_vm.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/shared/widgets/button/custom_button_blue.dart';

class ListSpecialtyPage extends StatefulWidget {
  const ListSpecialtyPage({super.key});

  @override
  State<ListSpecialtyPage> createState() => _ListSpecialtyPageState();
}

class _ListSpecialtyPageState extends State<ListSpecialtyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpecialtyVm>(context, listen: false).fetchSpecialties(refresh: true);
    });
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<SpecialtyVm>(context, listen: false).fetchSpecialties();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(dynamic specialty) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.popover,
        title: Text('Xác nhận xóa', style: TextStyle(color: context.theme.popoverForeground)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa chuyên khoa: ${specialty['name']}?',
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
                border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.ring)),
                filled: true,
                fillColor: context.theme.input,
              ),
              onSubmitted: (_) => _confirmDelete(specialty['id'], passwordController.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: context.theme.mutedForeground)),
          ),
          TextButton(
            onPressed: () => _confirmDelete(specialty['id'], passwordController.text),
            child: Text('Xóa', style: TextStyle(color: context.theme.destructive)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String id, String password) async {
    Navigator.pop(context);
    final provider = Provider.of<SpecialtyVm>(context, listen: false);
    final success = await provider.deleteSpecialty(id, password);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa chuyên khoa thành công!', style: TextStyle(color: context.theme.primaryForeground)),
          backgroundColor: context.theme.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xóa thất bại. Kiểm tra mật khẩu hoặc thử lại.', style: TextStyle(color: context.theme.destructiveForeground)),
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
          'Quản lý Chuyên khoa',
          style: TextStyle(color: context.theme.primaryForeground),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.theme.primaryForeground),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.theme.primaryForeground),
            onPressed: () => Provider.of<SpecialtyVm>(context, listen: false).fetchSpecialties(refresh: true),
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
                    labelText: 'Tìm kiếm theo tên',
                    labelStyle: TextStyle(color: context.theme.mutedForeground),
                    prefixIcon: Icon(Icons.search, color: context.theme.primary),
                    border: OutlineInputBorder(borderSide: BorderSide(color: context.theme.border)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: context.theme.ring)),
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
                  onTap: () => Navigator.pushNamed(context, Routes.createSpecialty),
                  text: 'Thêm chuyên khoa',
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SpecialtyVm>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.specialties.isEmpty) {
                  return Center(child: CircularProgressIndicator(color: context.theme.primary));
                }
                if (provider.error != null) {
                  return Center(child: Text(provider.error!, style: TextStyle(color: context.theme.destructive)));
                }
                final filteredSpecialties = provider.specialties.where((spec) {
                  final name = spec['name']?.toLowerCase() ?? '';
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query);
                }).toList();

                if (filteredSpecialties.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_information_outlined, size: 64, color: context.theme.muted),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'Không tìm thấy chuyên khoa phù hợp' : 'Danh sách chuyên khoa trống',
                          style: TextStyle(fontSize: 18, color: context.theme.mutedForeground),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredSpecialties.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredSpecialties.length) {
                      return Center(child: CircularProgressIndicator(color: context.theme.primary));
                    }
                    final specialty = filteredSpecialties[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: context.theme.card,
                      child: ListTile(
                        textColor: context.theme.cardForeground,
                        leading: CircleAvatar(
                          backgroundColor: context.theme.primary,
                          child: Text(
                            specialty['name']?[0].toUpperCase() ?? 'S',
                            style: TextStyle(color: context.theme.primaryForeground),
                          ),
                        ),
                        title: Text(specialty['name'] ?? 'N/A'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(specialty['description'] ?? 'N/A', style: TextStyle(color: context.theme.mutedForeground)),
                            Text('Số phần thông tin: ${specialty['infoSectionsCount'] ?? 0}', style: TextStyle(color: context.theme.mutedForeground)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: context.theme.primary),
                              onPressed: () => Navigator.pushNamed(
                                context,
                                Routes.updateSpecialty,
                                arguments: specialty,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: context.theme.destructive),
                              onPressed: () => _showDeleteDialog(specialty),
                            ),
                          ],
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          Routes.specialtyDetail,
                          arguments: specialty,
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