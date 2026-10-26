import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/core/utils/formatters.dart';
import 'package:printagx_app/data/models/job_work.dart';
import 'package:printagx_app/viewmodels/attendance_view_model.dart';
import 'package:printagx_app/viewmodels/auth_view_model.dart';
import 'package:printagx_app/viewmodels/job_list_view_model.dart';
import 'package:printagx_app/views/attendance/attendance_actions.dart';
import 'package:printagx_app/views/jobs/job_detail_view.dart';
import 'package:printagx_app/views/shell/app_shell.dart';
import 'package:printagx_app/views/widgets/common.dart';

/// "Today" tab: shift status, the job in hand, workload and what's next.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => Future.wait([
    context.read<AttendanceViewModel>().load(),
    context.read<JobListViewModel>().load(),
  ]);

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      const _Header(),
      const _ShiftCard(),
      const _CurrentJob(),
      const _Workload(),
      const _UpNext(),
    ];

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.lg,
            AppSpace.gutter,
            AppSpace.xxxl,
          ),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpace.xxl),
          itemBuilder: (_, i) => FadeSlideIn.indexed(i, child: sections[i]),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final name = context.select((AuthViewModel vm) => vm.fullName);
    final now = DateTime.now();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatLongDate(now).toUpperCase(),
                style: context.text.labelSmall,
              ),
              const SizedBox(height: AppSpace.sm),
              Text('${greetingFor(now)},', style: context.text.bodyLarge),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.md),
        Semantics(
          button: true,
          label: 'Open profile',
          child: GestureDetector(
            onTap: () => AppShell.of(context).select(AppTab.profile),
            child: InitialsAvatar(name: name, size: 52),
          ),
        ),
      ],
    );
  }
}

// ── Shift (attendance) ──────────────────────────────────────────────────────

class _ShiftCard extends StatelessWidget {
  const _ShiftCard();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceViewModel>();
    final p = context.palette;

    if (vm.isFirstLoad) {
      return const SkeletonBox(height: 196, radius: AppRadius.xl);
    }

    final isIn = vm.isCheckedIn;
    final since = vm.lastEventTime;
    final title = isIn
        ? 'You\'re checked in'
        : vm.hasActivity
        ? 'You\'re checked out'
        : 'Not checked in yet';
    final subtitle = since == null
        ? 'Check in to start your day'
        : isIn
        ? 'On shift since ${formatClock(since)}'
        : 'Last check-out at ${formatClock(since)}';

    return HeroCard(
      color: isIn ? p.success : null,
      onTap: () => AppShell.of(context).select(AppTab.attendance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ShiftChip(onShift: isIn),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                size: AppIconSize.md,
                color: p.onHeroMuted,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            title,
            style: context.text.titleLarge?.copyWith(color: p.onHero),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.text.bodyMedium?.copyWith(color: p.onHeroMuted),
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Ticking(
                  active: isIn,
                  builder: (_) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.hasActivity
                            ? formatDurationShort(vm.workedToday)
                            : '0m',
                        style: context.text.displaySmall?.copyWith(
                          color: p.onHero,
                          fontSize: 34,
                          fontFeatures: tabularFigures,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'worked today',
                        style: context.text.bodySmall?.copyWith(
                          color: p.onHeroMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              SizedBox(
                width: 148,
                child: AppButton(
                  key: ValueKey(isIn),
                  label: isIn ? 'Check out' : 'Check in',
                  icon: isIn ? Icons.logout_rounded : Icons.login_rounded,
                  variant: isIn
                      ? AppButtonVariant.inverse
                      : AppButtonVariant.primary,
                  compact: true,
                  loading: vm.isSubmitting,
                  onPressed: () => toggleAttendance(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  final bool onShift;
  const _ShiftChip({required this.onShift});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          onShift
              ? const LiveDot(color: Colors.white, size: 7)
              : Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white38,
                  ),
                ),
          const SizedBox(width: AppSpace.sm),
          Text(
            onShift ? 'ON SHIFT' : 'OFF SHIFT',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Current job ─────────────────────────────────────────────────────────────

class _CurrentJob extends StatelessWidget {
  const _CurrentJob();

  @override
  Widget build(BuildContext context) {
    final job = context.select((JobListViewModel vm) => vm.currentJob);
    // Rebuild on every list reload so the running timer reflects new logs.
    context.select((JobListViewModel vm) => vm.isLoading);

    return AnimatedSize(
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: job == null
          ? const SizedBox(width: double.infinity)
          : _CurrentJobCard(job: job),
    );
  }
}

class _CurrentJobCard extends StatelessWidget {
  final JobWork job;
  const _CurrentJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final running = job.activeSince != null;
    final accent = running ? p.primary : p.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          running ? 'Now working on' : 'Pick up where you left off',
        ),
        AppCard(
          onTap: () => JobDetailView.open(context, job),
          borderColor: accent.withValues(alpha: 0.35),
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusPill(
                                status: job.customJobStatus,
                                dense: true,
                              ),
                              const SizedBox(height: AppSpace.sm),
                              Text(
                                job.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  job.jobOrder,
                                  job.customCustomerName,
                                ].where((e) => e.isNotEmpty).join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Ticking(
                          active: running,
                          builder: (_) => Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatTimer(job.trackedTime),
                                style: context.text.titleLarge?.copyWith(
                                  color: accent,
                                  fontFeatures: tabularFigures,
                                ),
                              ),
                              Text('tracked', style: context.text.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Workload ────────────────────────────────────────────────────────────────

class _Workload extends StatelessWidget {
  const _Workload();

  static const _statuses = ['Open', 'In Progress', 'Stopped', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JobListViewModel>();
    final shell = AppShell.of(context);

    Widget body;
    if (vm.jobs == null && vm.error != null) {
      body = AppCard(
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: context.palette.danger),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                'Couldn\'t load your jobs.',
                style: context.text.bodyMedium,
              ),
            ),
            TextButton(onPressed: vm.load, child: const Text('Retry')),
          ],
        ),
      );
    } else if (vm.jobs == null) {
      body = const SkeletonBox(height: 172, radius: AppRadius.lg);
    } else {
      final total = vm.countFor('All');
      final done = vm.countFor('Completed');
      body = AppCard(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('${total - done}', style: context.text.headlineMedium),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    'open of $total assigned',
                    style: context.text.bodyMedium,
                  ),
                ),
                Text(
                  total == 0 ? '' : '${(done * 100 / total).round()}% done',
                  style: context.text.labelMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            _SegmentBar(
              segments: [
                for (final s in _statuses)
                  (vm.countFor(s), StatusStyle.of(context, s).color),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final s in _statuses)
                  _LegendChip(
                    status: s,
                    count: vm.countFor(s),
                    onTap: () => shell.openJobs(s),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Workload',
          actionLabel: 'All jobs',
          onAction: () => shell.openJobs('All'),
        ),
        AnimatedSwitcher(duration: AppDurations.normal, child: body),
      ],
    );
  }
}

/// Horizontal stacked bar showing the share of each status.
class _SegmentBar extends StatelessWidget {
  final List<(int, Color)> segments;
  const _SegmentBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    final visible = segments.where((s) => s.$1 > 0).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: 10,
        child: visible.isEmpty
            ? SizedBox.expand(
                child: ColoredBox(color: context.palette.surfaceMuted),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: visible[i].$1,
                      child: ColoredBox(color: visible[i].$2),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final String status;
  final int count;
  final VoidCallback onTap;
  const _LegendChip({
    required this.status,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = StatusStyle.of(context, status);
    final p = context.palette;
    return Material(
      color: p.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: s.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Text(s.label, style: context.text.labelMedium),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: context.text.titleSmall?.copyWith(
                  fontFeatures: tabularFigures,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Up next ─────────────────────────────────────────────────────────────────

class _UpNext extends StatelessWidget {
  const _UpNext();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JobListViewModel>();
    if (vm.jobs == null) return const SizedBox.shrink();

    final current = vm.currentJob;
    final next = vm.openJobs.where((j) => j != current).take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Up next'),
        if (next.isEmpty)
          const InlineEmpty(
            'You\'re all caught up — no other open jobs.',
            icon: Icons.task_alt_rounded,
          )
        else
          for (var i = 0; i < next.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpace.sm),
            _CompactJobTile(job: next[i]),
          ],
      ],
    );
  }
}

class _CompactJobTile extends StatelessWidget {
  final JobWork job;
  const _CompactJobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final s = StatusStyle.of(context, job.customJobStatus);
    final p = context.palette;
    return AppCard(
      onTap: () => JobDetailView.open(context, job),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: 14,
      ),
      child: Row(
        children: [
          IconBadge(icon: s.icon, color: s.color, background: s.background),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    job.jobOrder,
                    job.customCustomerName,
                  ].where((e) => e.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ],
      ),
    );
  }
}
