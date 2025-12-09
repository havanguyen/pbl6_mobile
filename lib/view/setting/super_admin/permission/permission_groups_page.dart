import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/shared/localization/app_localizations.dart';
import 'package:pbl6mobile/shared/routes/routes.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:pbl6mobile/view_model/permission/permission_vm.dart';
import 'package:provider/provider.dart';

class ChartData {
  final String label;
  final int value;
  final String? subLabel;

  ChartData({required this.label, required this.value, this.subLabel});
}

class PermissionGroupsPage extends StatefulWidget {
  const PermissionGroupsPage({super.key});

  @override
  State<PermissionGroupsPage> createState() => _PermissionGroupsPageState();
}

class _PermissionGroupsPageState extends State<PermissionGroupsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _groupSearchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  String _groupSearch = '';
  String _userSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _groupSearchController.addListener(() {
      setState(() {
        _groupSearch = _groupSearchController.text;
      });
    });
    _userSearchController.addListener(() {
      setState(() {
        _userSearch = _userSearchController.text;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupSearchController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PermissionVm()
        ..getAllGroups()
        ..fetchUsers()
        ..fetchStats(),
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
                    text: AppLocalizations.of(
                      context,
                    ).translate('statistics_tab'),
                  ),
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
                _buildStatisticsTab(context, vm),
                _buildGroupsTab(context, vm),
                _buildUsersTab(context, vm),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsTab(BuildContext context, PermissionVm vm) {
    if (vm.isLoading && vm.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.stats == null) {
      final errorMsg = vm.error != null
          ? AppLocalizations.of(context).translate(vm.error!)
          : AppLocalizations.of(context).translate('no_statistics_available');
      return Center(
        child: Text(
          errorMsg,
          style: TextStyle(color: context.theme.mutedForeground),
        ),
      );
    }

    final stats = vm.stats!;

    return AnimationLimiter(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 375),
          childAnimationBuilder: (widget) => SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(child: widget),
          ),
          children: [
            // Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildGradientStatCard(
                    context,
                    AppLocalizations.of(context).translate('total_permissions'),
                    stats.totalPermissions.toString(),
                    Icons.lock_outline,
                    [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGradientStatCard(
                    context,
                    AppLocalizations.of(context).translate('total_groups'),
                    stats.totalGroups.toString(),
                    Icons.group_work_outlined,
                    [Colors.orange.shade400, Colors.orange.shade700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildGradientStatCard(
                    context,
                    AppLocalizations.of(context).translate('assigned_to_users'),
                    stats.totalUserPermissions.toString(),
                    Icons.person_outline,
                    [Colors.purple.shade400, Colors.purple.shade700],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildGradientStatCard(
                    context,
                    AppLocalizations.of(
                      context,
                    ).translate('assigned_to_groups'),
                    stats.totalGroupPermissions.toString(),
                    Icons.folder_shared_outlined,
                    [Colors.green.shade400, Colors.green.shade700],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            // Most Used Permissions Chart
            _buildSectionHeader(
              context,
              AppLocalizations.of(context).translate('most_used_permissions'),
              Icons.bar_chart,
            ),
            const SizedBox(height: 16),
            _buildCustomBarChart(
              context,
              stats.mostUsedPermissions
                  .map(
                    (e) => ChartData(
                      label: '${e.resource}:${e.action}',
                      value: e.usageCount,
                    ),
                  )
                  .toList(),
              context.theme.primary,
            ),

            const SizedBox(height: 32),
            // Largest Groups Chart
            _buildSectionHeader(
              context,
              AppLocalizations.of(context).translate('largest_groups'),
              Icons.pie_chart_outline, // Using generic chart icon
            ),
            const SizedBox(height: 16),
            _buildCustomBarChart(
              context,
              stats.largestGroups
                  .map(
                    (e) => ChartData(
                      label: e.groupName,
                      value: e.memberCount,
                      subLabel: '${e.groupId.substring(0, 8)}...',
                    ),
                  )
                  .toList(),
              Colors.indigo,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: context.theme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: context.theme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.theme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBarChart(
    BuildContext context,
    List<ChartData> data,
    Color color,
  ) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).translate('no_data'),
          style: TextStyle(color: context.theme.mutedForeground),
        ),
      );
    }

    final maxValue = data
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Column(
      children: data.map((item) {
        final percentage = maxValue == 0 ? 0.0 : item.value / maxValue;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.theme.textColor,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${item.value}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (item.subLabel != null)
                Text(
                  item.subLabel!,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.theme.mutedForeground,
                  ),
                ),
              const SizedBox(height: 6),
              Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.theme.input,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupsTab(BuildContext context, PermissionVm vm) {
    final filteredGroups = vm.groups
        .where(
          (g) =>
              g.name.toLowerCase().contains(_groupSearch.toLowerCase()) ||
              g.description.toLowerCase().contains(_groupSearch.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context, vm),
        backgroundColor: context.theme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(
            context,
            _groupSearchController,
            AppLocalizations.of(context).translate('search_groups_hint'),
          ),
          Expanded(
            child: vm.isLoading && vm.groups.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredGroups.isEmpty
                ? _buildEmptyState(
                    context,
                    AppLocalizations.of(
                      context,
                    ).translate('no_info_sections_yet'),
                  ) // Use generic "No items"
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredGroups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = filteredGroups[index];
                      return Card(
                        elevation: 0,
                        color: context.theme.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: context.theme.border),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.permissionGroupDetail,
                              arguments: group,
                            ).then((_) => vm.getAllGroups());
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: context.theme.primary.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.security,
                                    color: context.theme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: context.theme.textColor,
                                        ),
                                      ),
                                      if (group.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          group.description,
                                          style: TextStyle(
                                            color:
                                                context.theme.mutedForeground,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: context.theme.mutedForeground
                                      .withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context, PermissionVm vm) {
    final filteredUsers = vm.users
        .where(
          (u) =>
              u.fullName.toLowerCase().contains(_userSearch.toLowerCase()) ||
              u.email.toLowerCase().contains(_userSearch.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          _buildSearchBar(
            context,
            _userSearchController,
            AppLocalizations.of(context).translate('search_users_hint'),
          ),
          Expanded(
            child: vm.isLoading && vm.users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                ? _buildEmptyState(
                    context,
                    AppLocalizations.of(context).translate('no_patients_found'),
                  ) // Use generic not found
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        elevation: 0,
                        color: context.theme.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: context.theme.border),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.userPermissionDetail,
                              arguments: user,
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'user_avatar_${user.id}',
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: context.theme.primary
                                        .withOpacity(0.1),
                                    child: Text(
                                      user.fullName.isNotEmpty
                                          ? user.fullName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: context.theme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: context.theme.textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.theme.muted
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              user.role.toUpperCase(),
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
                                                color: context
                                                    .theme
                                                    .mutedForeground,
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
                                  color: context.theme.mutedForeground
                                      .withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    BuildContext context,
    TextEditingController controller,
    String hint,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.card,
        border: Border(bottom: BorderSide(color: context.theme.border)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: context.theme.textColor),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.search, color: context.theme.mutedForeground),
          filled: true,
          fillColor: context.theme.input,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: TextStyle(color: context.theme.mutedForeground),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: context.theme.mutedForeground.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: context.theme.mutedForeground,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, PermissionVm vm) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppLocalizations.of(context).translate('create_group_title'),
          style: TextStyle(color: context.theme.textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).translate('group_name_label'),
                labelStyle: TextStyle(color: context.theme.mutedForeground),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: TextStyle(color: context.theme.textColor),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).translate('group_desc_label'),
                labelStyle: TextStyle(color: context.theme.mutedForeground),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.theme.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(color: context.theme.mutedForeground),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
                    backgroundColor: context.theme.green,
                    content: Text(
                      AppLocalizations.of(context).translate('create_success'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              } else if (!success && context.mounted) {
                final errorMsg = vm.error != null
                    ? AppLocalizations.of(context).translate(vm.error!)
                    : AppLocalizations.of(
                        context,
                      ).translate('create_failed'); // fallback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: context.theme.destructive,
                    content: Text(
                      errorMsg,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context).translate('create')),
          ),
        ],
      ),
    );
  }
}
