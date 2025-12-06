import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:pbl6mobile/view_model/permission/permission_vm.dart';
import 'package:provider/provider.dart';

class PermissionGroupsPage extends StatefulWidget {
  const PermissionGroupsPage({super.key});

  @override
  State<PermissionGroupsPage> createState() => _PermissionGroupsPageState();
}

class _PermissionGroupsPageState extends State<PermissionGroupsPage>
    with SingleTickerProviderStateMixin {
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
      create: (_) => PermissionVm()
        ..getAllGroups()
        ..fetchUsers(),
      child: Consumer<PermissionVm>(
        builder: (context, vm, child) {
          return Scaffold(
            backgroundColor: context.theme.bg,
            appBar: AppBar(
              backgroundColor: context.theme.blue,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: context.theme.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                AppLocalizations.of(
                  context,
                ).translate('permission_management_title'),
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
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    text: AppLocalizations.of(context).translate('group_tab'),
                  ),
                  Tab(text: AppLocalizations.of(context).translate('user_tab')),
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
      body: vm.isLoading && vm.groups.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = vm.groups[index];
                return Card(
                  elevation: 0,
                  color: context.theme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: context.theme.border.withOpacity(0.2),
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.permissionGroupDetail,
                        arguments: group,
                      ).then((_) => vm.getAllGroups());
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.theme.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.security,
                              color: context.theme.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.theme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  group.description,
                                  style: TextStyle(
                                    color: context.theme.grey,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: context.theme.grey.withOpacity(0.5),
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
    return vm.isLoading && vm.users.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: vm.users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = vm.users[index];
              return Card(
                elevation: 0,
                color: context.theme.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: context.theme.border.withOpacity(0.2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.userPermissionDetail,
                      arguments: user,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: context.theme.blue.withOpacity(0.1),
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: context.theme.blue,
                              fontWeight: FontWeight.bold,
                            ),
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
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.theme.grey.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      user.role
                                          .toUpperCase(), // 'Doctor' -> 'DOCTOR'
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: context.theme.textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user.email,
                                      style: TextStyle(
                                        color: context.theme.grey,
                                        fontSize: 12,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: context.theme.grey.withOpacity(0.5),
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
          AppLocalizations.of(context).translate('create_group_title'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).translate('group_name_label'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).translate('group_desc_label'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: context.theme.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await vm.createGroup(
                nameController.text,
                descController.text,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).translate('create_success'),
                    ),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context).translate('create_btn')),
          ),
        ],
      ),
    );
  }
}
