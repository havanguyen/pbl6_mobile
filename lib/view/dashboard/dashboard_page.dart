import 'package:flutter/material.dart';
import 'package:pbl6mobile/shared/extensions/custome_theme_extension.dart';
import 'package:pbl6mobile/view/dashboard/tabs/dashboard_overview.dart';
import 'package:pbl6mobile/view/dashboard/tabs/dashboard_analytics.dart';
import 'package:pbl6mobile/view_model/stats/stats_vm.dart';
import 'package:provider/provider.dart';
import '../../../shared/localization/app_localizations.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatsVm()..refreshAll(),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatsVm>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: context.theme.bg,
        appBar: AppBar(
          backgroundColor: context.theme.card,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.theme.textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context).translate('dashboard'),
            style: TextStyle(
              color: context.theme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: TabBar(
            labelColor: context.theme.primary,
            unselectedLabelColor: context.theme.mutedForeground,
            indicatorColor: context.theme.primary,
            tabs: [
              Tab(text: AppLocalizations.of(context).translate('overview')),
              Tab(text: AppLocalizations.of(context).translate('analytics')),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: context.theme.textColor),
              onPressed: () => vm.refreshAll(force: true),
            ),
          ],
        ),
        body: TabBarView(
          children: [const DashboardOverview(), const DashboardAnalytics()],
        ),
      ),
    );
  }
}
