import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/core/utils/formatters.dart';
import 'package:printagx_app/data/models/job_work.dart';
import 'package:printagx_app/data/repositories/job_repository.dart';
import 'package:printagx_app/viewmodels/job_detail_view_model.dart';
import 'package:printagx_app/viewmodels/job_list_view_model.dart';
import 'package:printagx_app/views/widgets/common.dart';

class JobDetailView extends StatelessWidget {
  final JobWork job;
  const JobDetailView({super.key, required this.job});

  /// Pushes the detail page, then refreshes the shared job list on return.
  static Future<void> open(BuildContext context, JobWork job) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JobDetailView(job: job)),
    );
    if (context.mounted) context.read<JobListViewModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => JobDetailViewModel(c.read<JobRepository>(), job),
      child: const _JobDetailBody(),
    );
  }
}

class _JobDetailBody extends StatelessWidget {
  const _JobDetailBody();

  Future<void> _run(
    BuildContext context,
    Future<void> Function(JobDetailViewModel vm) action,
  ) async {
    final vm = context.read<JobDetailViewModel>();
    await action(vm);
    if (!context.mounted) return;
    if (vm.errorMessage != null) {
      showAppSnack(context, vm.errorMessage!, error: true);
    } else if (vm.successMessage != null) {
      showAppSnack(context, vm.successMessage!);
    }
  }

  Future<void> _complete(BuildContext context) async {
    final vm = context.read<JobDetailViewModel>();
    final ok = await confirmAction(
      context,
      title: 'Mark job as complete?',
      message:
          'This closes ${vm.job.jobOrder} with '
          '${formatDurationShort(vm.totalTracked)} logged. '
          'You won\'t be able to log more time on it.',
      confirmLabel: 'Complete',
      icon: Icons.done_all_rounded,
      tone: ConfirmTone.success,
    );
    if (ok && context.mounted) await _run(context, (vm) => vm.complete());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JobDetailViewModel>();
    final job = vm.job;

    final sections = <Widget>[
      _TimerHero(vm: vm),
      _DetailsSection(job: job),
      if (job.customItems.isNotEmpty) _ItemsSection(items: job.customItems),
      if (job.customEmployees.isNotEmpty)
        _TeamSection(employees: job.customEmployees),
      _SessionsSection(logs: vm.timeLogs),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(job.jobOrder),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.lg),
            child: Center(child: StatusPill(status: vm.statusKey)),
          ),
        ],
      ),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.sm,
          AppSpace.gutter,
          AppSpace.xxxl,
        ),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.xxl),
        itemBuilder: (_, i) => FadeSlideIn.indexed(i, child: sections[i]),
      ),
      bottomNavigationBar: BottomActionBar(child: _buildActions(context, vm)),
    );
  }

  Widget _buildActions(BuildContext context, JobDetailViewModel vm) {
    final p = context.palette;
    final loading = vm.isLoading;
    switch (vm.status) {
      case JobWorkStatus.completed:
        return Container(
          key: const ValueKey('done'),
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            color: p.successSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded, color: p.success),
              const SizedBox(width: AppSpace.sm),
              Text(
                'This job is completed',
                style: context.text.labelLarge?.copyWith(color: p.success),
              ),
            ],
          ),
        );
      case JobWorkStatus.idle:
        return AppButton(
          key: const ValueKey('start'),
          label: 'Start work',
          icon: Icons.play_arrow_rounded,
          loading: loading,
          onPressed: () => _run(context, (vm) => vm.start()),
        );
      case JobWorkStatus.running:
        return AppButton(
          key: const ValueKey('pause'),
          label: 'Pause',
          icon: Icons.pause_rounded,
          variant: AppButtonVariant.tonal,
          loading: loading,
          onPressed: () => _run(context, (vm) => vm.pause()),
        );
      case JobWorkStatus.stopped:
        return Row(
          key: const ValueKey('stopped'),
          children: [
            Expanded(
              child: AppButton(
                label: 'Resume',
                icon: Icons.play_arrow_rounded,
                variant: AppButtonVariant.outline,
                onPressed: loading
                    ? null
                    : () => _run(context, (vm) => vm.resume()),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: AppButton(
                label: 'Complete',
                icon: Icons.done_all_rounded,
                variant: AppButtonVariant.success,
                loading: loading,
                onPressed: () => _complete(context),
              ),
            ),
          ],
        );
    }
  }
}

// ── Timer hero ──────────────────────────────────────────────────────────────

class _TimerHero extends StatelessWidget {
  final JobDetailViewModel vm;
  const _TimerHero({required this.vm});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final job = vm.job;
    final running = vm.status == JobWorkStatus.running;
    final since = vm.activeSince;
    final expected = Duration(minutes: job.expectedTimeRequiredInMins.round());

    final caption = switch (vm.status) {
      JobWorkStatus.running when since != null =>
        'Running since ${formatClock(since)}',
      JobWorkStatus.running => 'Running',
      JobWorkStatus.stopped => 'Paused · tap Resume to continue',
      JobWorkStatus.completed => 'Total time spent',
      JobWorkStatus.idle => 'Not started yet',
    };

    return HeroCard(
      color: switch (vm.status) {
        JobWorkStatus.running => p.primary,
        JobWorkStatus.completed => p.success,
        _ => null,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              job.customServiceType,
              job.operation,
            ].where((e) => e.isNotEmpty).join(' · ').toUpperCase(),
            style: context.text.labelSmall?.copyWith(color: p.onHeroMuted),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            job.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.headlineSmall?.copyWith(color: p.onHero),
          ),
          const SizedBox(height: AppSpace.xxl),
          Ticking(
            active: running,
            builder: (_) {
              final tracked = vm.totalTracked;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatTimer(tracked),
                      style: context.text.displayMedium?.copyWith(
                        color: p.onHero,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ),
                  if (expected > Duration.zero) ...[
                    const SizedBox(height: AppSpace.lg),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: (tracked.inSeconds / expected.inSeconds).clamp(
                          0.0,
                          1.0,
                        ),
                        minHeight: 6,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      '${formatDurationShort(tracked)} of '
                      '${formatDurationShort(expected)} estimated',
                      style: context.text.bodySmall?.copyWith(
                        color: p.onHeroMuted,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              if (running) ...[
                const LiveDot(color: Colors.white),
                const SizedBox(width: AppSpace.sm),
              ],
              Expanded(
                child: Text(
                  caption,
                  style: context.text.bodyMedium?.copyWith(
                    color: p.onHeroMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Details ─────────────────────────────────────────────────────────────────

class _DetailsSection extends StatelessWidget {
  final JobWork job;
  const _DetailsSection({required this.job});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Details'),
        AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.xs,
          ),
          child: Column(
            children: [
              InfoRow(
                icon: Icons.storefront_outlined,
                label: 'Customer',
                value: job.customCustomerName,
              ),
              InfoRow(
                icon: Icons.receipt_long_outlined,
                label: 'Sales order',
                value: job.customSalesOrderNumber,
              ),
              InfoRow(
                icon: Icons.print_outlined,
                label: 'Service',
                value: job.customServiceType,
              ),
              InfoRow(
                icon: Icons.tune_rounded,
                label: 'Operation',
                value: job.operation,
              ),
              InfoRow(
                icon: Icons.event_outlined,
                label: 'Posted on',
                value: formatDate(job.postingDate),
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Items ───────────────────────────────────────────────────────────────────

class _ItemsSection extends StatelessWidget {
  final List<CustomItem> items;
  const _ItemsSection({required this.items});

  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final totalCopies = items.fold<double>(0, (sum, i) => sum + i.copies);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Items',
          trailing: Text(
            '${items.length} item${items.length == 1 ? '' : 's'} · '
            '${_num(totalCopies)} copies',
            style: context.text.labelMedium,
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Container(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  decoration: BoxDecoration(
                    border: i == items.length - 1
                        ? null
                        : Border(bottom: BorderSide(color: p.border)),
                  ),
                  child: Row(
                    children: [
                      IconBadge(
                        icon: Icons.layers_outlined,
                        color: p.info,
                        background: p.infoSoft,
                        size: 40,
                      ),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[i].itemName,
                              style: context.text.titleSmall,
                            ),
                            if ((items[i].remarks?.toString() ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                items[i].remarks.toString(),
                                style: context.text.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _num(items[i].copies),
                            style: context.text.titleMedium?.copyWith(
                              fontFeatures: tabularFigures,
                            ),
                          ),
                          Text('copies', style: context.text.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Team ────────────────────────────────────────────────────────────────────

class _TeamSection extends StatelessWidget {
  final List<CustomEmployee> employees;
  const _TeamSection({required this.employees});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Assigned team'),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final e in employees)
              Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 14, 4),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: p.primarySoft,
                      child: Text(
                        initialsOf(e.name1.isNotEmpty ? e.name1 : e.employees),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      e.name1.isNotEmpty ? e.name1 : e.employees,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Work sessions ───────────────────────────────────────────────────────────

class _SessionsSection extends StatelessWidget {
  final List<TimeLog> logs;
  const _SessionsSection({required this.logs});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Work sessions',
          trailing: logs.isEmpty
              ? null
              : Text('${logs.length} logged', style: context.text.labelMedium),
        ),
        if (logs.isEmpty)
          const InlineEmpty(
            'No time logged yet. Tap "Start work" to begin tracking.',
            icon: Icons.timer_outlined,
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.sm,
            ),
            child: Column(
              children: [
                for (var i = 0; i < logs.length; i++)
                  _SessionRow(log: logs[i], isLast: i == logs.length - 1),
              ],
            ),
          ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  final TimeLog log;
  final bool isLast;
  const _SessionRow({required this.log, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final running = log.toTime == null;
    final from = log.fromTime!;
    final sameDay = DateUtils.isSameDay(from, DateTime.now());
    final color = running ? p.primary : p.textMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail.
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 18),
                running
                    ? LiveDot(color: color, size: 10)
                    : Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                      ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(top: AppSpace.xs),
                      color: p.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    running
                        ? '${formatClock(from)} – now'
                        : '${formatClock(from)} – ${formatClock(log.toTime!)}',
                    style: context.text.titleSmall?.copyWith(
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sameDay ? 'Today' : formatDate(from),
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Ticking(
              active: running,
              builder: (_) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: running ? p.primarySoft : p.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  formatDurationShort(
                    (log.toTime ?? DateTime.now()).difference(from),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: running ? p.primary : p.textPrimary,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
