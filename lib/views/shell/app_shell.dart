import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/viewmodels/attendance_view_model.dart';
import 'package:printagx_app/viewmodels/job_list_view_model.dart';
import 'package:printagx_app/views/attendance/attendance_view.dart';
import 'package:printagx_app/views/home/home_view.dart';
import 'package:printagx_app/views/jobs/job_list_view.dart';
import 'package:printagx_app/views/profile/profile_view.dart';
import 'package:printagx_app/views/shell/app_nav_bar.dart';

enum AppTab { today, jobs, attendance, profile }

/// Signed-in root: four tabs behind a bottom navigation bar. Tabs are built
/// on first visit and then kept alive so scroll position and search persist.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  static AppShellState of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>()!;

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  AppTab _tab = AppTab.today;
  final _visited = <AppTab>{AppTab.today};

  void select(AppTab tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
  }

  /// Switches to the Jobs tab, optionally pre-filtered by status.
  void openJobs([String? filter]) {
    if (filter != null) context.read<JobListViewModel>().setFilter(filter);
    select(AppTab.jobs);
  }

  Widget _page(AppTab tab) => switch (tab) {
    AppTab.today => const HomeView(),
    AppTab.jobs => const JobListView(),
    AppTab.attendance => const AttendanceView(),
    AppTab.profile => const ProfileView(),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasRunningJob = context.select(
      (JobListViewModel vm) => vm.hasRunningJob,
    );
    final isCheckedIn = context.select(
      (AttendanceViewModel vm) => vm.isCheckedIn,
    );

    return PopScope(
      // Back from any tab returns to Today before leaving the app.
      canPop: _tab == AppTab.today,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) select(AppTab.today);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: p.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: IndexedStack(
            index: _tab.index,
            children: [
              for (final tab in AppTab.values)
                _visited.contains(tab)
                    ? _TabPage(active: tab == _tab, child: _page(tab))
                    : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: AppNavBar(
            currentIndex: _tab.index,
            onSelect: (i) => select(AppTab.values[i]),
            items: [
              const AppNavItem(
                label: 'Today',
                icon: Icons.space_dashboard_outlined,
                activeIcon: Icons.space_dashboard_rounded,
              ),
              AppNavItem(
                label: 'Jobs',
                icon: Icons.assignment_outlined,
                activeIcon: Icons.assignment_rounded,
                badgeColor: hasRunningJob ? p.primary : null,
              ),
              AppNavItem(
                label: 'Attendance',
                icon: Icons.schedule_outlined,
                activeIcon: Icons.schedule_rounded,
                badgeColor: isCheckedIn ? p.success : null,
              ),
              const AppNavItem(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades a tab in each time it becomes the active one.
class _TabPage extends StatefulWidget {
  final bool active;
  final Widget child;
  const _TabPage({required this.active, required this.child});

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDurations.normal,
  )..forward();

  @override
  void didUpdateWidget(_TabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.012),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}
