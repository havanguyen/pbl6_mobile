import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/permission/permission_vm.dart';

class PermissionGroupsPage extends StatelessWidget {
  const PermissionGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionVm()..fetchGroups(),
      child: Scaffold(
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
            'Quản lý phân quyền',
            style: TextStyle(
              color: context.theme.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: Consumer<PermissionVm>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vm.error!,
                      style: TextStyle(color: context.theme.destructive),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.fetchGroups(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            if (vm.groups.isEmpty) {
              return Center(
                child: Text(
                  'Chưa có nhóm quyền nào',
                  style: TextStyle(color: context.theme.textColor),
                ),
              );
            }

            return ListView.separated(
              itemCount: vm.groups.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Colors.grey),
              itemBuilder: (context, index) {
                final group = vm.groups[index];
                return ListTile(
                  title: Text(
                    group.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.theme.textColor,
                    ),
                  ),
                  subtitle: Text(
                    group.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.theme.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: context.theme.grey,
                  ),
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      Routes.permissionGroupDetail,
                      arguments: group,
                    );
                    // Refresh list when returning
                    vm.fetchGroups();
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              backgroundColor: context.theme.blue,
              onPressed: () {
                _showCreateGroupDialog(context);
              },
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final vm = context.read<PermissionVm>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.bg,
        title: Text('Thêm nhóm quyền', style: TextStyle(color: context.theme.textColor)),
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
              if (nameController.text.isNotEmpty) {
                final success = await vm.createGroup(
                  nameController.text,
                  descController.text,
                );
                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: Text('Lưu', style: TextStyle(color: context.theme.blue)),
          ),
        ],
      ),
    );
  }
}
