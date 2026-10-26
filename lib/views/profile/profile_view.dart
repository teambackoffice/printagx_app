import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/core/utils/formatters.dart';
import 'package:printagx_app/viewmodels/attendance_view_model.dart';
import 'package:printagx_app/viewmodels/auth_view_model.dart';
import 'package:printagx_app/viewmodels/job_list_view_model.dart';
import 'package:printagx_app/views/auth/login_view.dart';
import 'package:printagx_app/views/shell/app_shell.dart';
import 'package:printagx_app/views/widgets/common.dart';

/// "Profile" tab: who's signed in, today's numbers, and sign-out.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your jobs.',
      confirmLabel: 'Log out',
      icon: Icons.logout_rounded,
      tone: ConfirmTone.danger,
    );
    if (!confirmed || !context.mounted) return;

    final success = await context.read<AuthViewModel>().logout();
    if (!context.mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: AppDurations.slow,
          pageBuilder: (_, _, _) => const LoginView(),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
        (route) => false,
      );
    } else {
      showAppSnack(context, 'Logout failed. Please try again.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final p = context.palette;

    return SafeArea(
      bottom: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.lg,
          AppSpace.gutter,
          AppSpace.xxxl,
        ),
        children: [
          const PageHeader(title: 'Profile'),
          const SizedBox(height: AppSpace.xxl),
          FadeSlideIn(
            child: _IdentityCard(
              name: auth.fullName,
              employeeId: auth.employeeId,
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
          FadeSlideIn.indexed(1, child: const _TodayStats()),
          const SizedBox(height: AppSpace.xxl),
          FadeSlideIn.indexed(
            2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Account'),
                AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.xs,
                  ),
                  child: Column(
                    children: [
                      InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Full name',
                        value: auth.fullName,
                      ),
                      InfoRow(
                        icon: Icons.tag_rounded,
                        label: 'Employee ID',
                        value: auth.employeeId,
                      ),
                      const InfoRow(
                        icon: Icons.business_outlined,
                        label: 'Workspace',
                        value: 'Screen Arts',
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                AppCard(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Row(
                    children: [
                      IconBadge(
                        icon: Icons.support_agent_rounded,
                        color: p.info,
                        background: p.infoSoft,
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Need help?', style: context.text.titleSmall),
                            const SizedBox(height: 2),
                            Text(
                              'Contact your admin for access or account '
                              'issues.',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                AppCard(
                  onTap: auth.isLoggingOut
                      ? null
                      : () => _confirmLogout(context),
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Row(
                    children: [
                      IconBadge(
                        icon: Icons.logout_rounded,
                        color: p.danger,
                        background: p.dangerSoft,
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Text(
                          'Log out',
                          style: context.text.titleSmall?.copyWith(
                            color: p.danger,
                          ),
                        ),
                      ),
                      if (auth.isLoggingOut)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: p.danger,
                          ),
                        )
                      else
                        Icon(Icons.chevron_right_rounded, color: p.textMuted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String name;
  final String employeeId;
  const _IdentityCard({required this.name, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return HeroCard(
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(3),
            child: InitialsAvatar(name: name, size: 64),
          ),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge?.copyWith(color: p.onHero),
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.xs,
                  children: [
                    if (employeeId.isNotEmpty) _HeroTag(text: employeeId),
                    const _HeroTag(text: 'Production'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String text;
  const _HeroTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TodayStats extends StatelessWidget {
  const _TodayStats();

  @override
  Widget build(BuildContext context) {
    final attendance = context.watch<AttendanceViewModel>();
    final jobs = context.watch<JobListViewModel>();
    final p = context.palette;
    final shell = AppShell.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Today at a glance'),
        _TileGrid(
          children: [
            Ticking(
              active: attendance.isCheckedIn,
              builder: (_) => _StatTile(
                icon: Icons.schedule_rounded,
                color: p.success,
                background: p.successSoft,
                value: formatDurationShort(attendance.workedToday),
                label: 'Worked today',
                onTap: () => shell.select(AppTab.attendance),
              ),
            ),
            _StatTile(
              icon: Icons.repeat_rounded,
              color: p.info,
              background: p.infoSoft,
              value: '${attendance.sessionCount}',
              label: 'Shift sessions',
              onTap: () => shell.select(AppTab.attendance),
            ),
            _StatTile(
              icon: Icons.pending_actions_rounded,
              color: p.warning,
              background: p.warningSoft,
              value: jobs.jobs == null ? '—' : '${jobs.openJobs.length}',
              label: 'Open jobs',
              onTap: () => shell.openJobs('All'),
            ),
            _StatTile(
              icon: Icons.task_alt_rounded,
              color: p.primary,
              background: p.primarySoft,
              value: jobs.jobs == null ? '—' : '${jobs.countFor('Completed')}',
              label: 'Completed',
              onTap: () => shell.openJobs('Completed'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.background,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, background: background, size: 32),
          const SizedBox(height: AppSpace.lg),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: context.text.headlineSmall?.copyWith(
                fontFeatures: tabularFigures,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Two-column grid whose rows size to their content.
class _TileGrid extends StatelessWidget {
  final List<Widget> children;
  const _TileGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) const SizedBox(height: AppSpace.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
