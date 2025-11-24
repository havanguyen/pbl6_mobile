import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/permission/permission_vm.dart';
import 'package:provider/provider.dart';

class PermissionGroupsPage extends StatefulWidget {
  const PermissionGroupsPage({super.key});

  @override
  State<PermissionGroupsPage> createState() => _PermissionGroupsPageState();
}

class _PermissionGroupsPageState extends State<PermissionGroupsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionVm()..getAllGroups()..fetchUsers(),
      child: Consumer<PermissionVm>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: context.theme.bg,
            appBar: AppBar(
              backgroundColor: context.theme.blue,
              elevation: 0.5,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: context.theme.white,
                  size: 28,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(
                'Phân quyền & Nhóm quyền',
                style: TextStyle(
                  color: context.theme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: context.theme.white,
                labelColor: context.theme.white,
                unselectedLabelColor: context.theme.white.withOpacity(0.6),
                tabs: const [
                  Tab(text: 'Nhóm quyền'),
                  Tab(text: 'Người dùng'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupsTab(context, vm),
                _buildUsersTab(context, vm),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupsTab(BuildContext context, PermissionVm vm) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context, vm),
        backgroundColor: context.theme.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.groups.length,
              itemBuilder: (context, index) {
                final group = vm.groups[index];
                return Card(
                  color: context.theme.bg,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: context.theme.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.permissionGroupDetail,
                        arguments: group,
                      ).then((_) => vm.getAllGroups());
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.theme.textColor,
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: context.theme.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            group.description,
                            style: TextStyle(
                              color: context.theme.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildUsersTab(BuildContext context, PermissionVm vm) {
    return vm.isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.users.length,
            itemBuilder: (context, index) {
              final user = vm.users[index];
              return Card(
                color: context.theme.bg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: context.theme.grey.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.userPermissionDetail,
                      arguments: user,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: context.theme.blue.withOpacity(0.1),
                          child: Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                            style: TextStyle(color: context.theme.blue),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.theme.textColor,
                                ),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: context.theme.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: context.theme.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }

  void _showCreateGroupDialog(BuildContext context, PermissionVm vm) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.bg,
        title: Text(
          'Tạo nhóm quyền mới',
          style: TextStyle(color: context.theme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên nhóm',
                labelStyle: TextStyle(color: context.theme.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.grey),
                ),
              ),
              style: TextStyle(color: context.theme.textColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                labelStyle: TextStyle(color: context.theme.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.grey),
                ),
              ),
              style: TextStyle(color: context.theme.textColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: context.theme.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await vm.createGroup(
                nameController.text,
                descController.text,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tạo nhóm thành công')),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(vm.error ?? 'Tạo nhóm thất bại')),
                );
              }
            },
            child: Text('Tạo', style: TextStyle(color: context.theme.blue)),
          ),
        ],
      ),
    );
  }
}
