import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/core/utils/formatters.dart';
import 'package:printagx_app/data/models/checkin_status.dart';
import 'package:printagx_app/viewmodels/attendance_view_model.dart';
import 'package:printagx_app/views/attendance/attendance_actions.dart';
import 'package:printagx_app/views/widgets/common.dart';

/// "Attendance" tab: live shift clock, today's summary and timeline.
class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AttendanceViewModel>().load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AttendanceViewModel>();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.gutter,
            AppSpace.lg,
            AppSpace.gutter,
            AppSpace.xxxl,
          ),
          children: [
            PageHeader(
              overline: formatLongDate(DateTime.now()),
              title: 'Attendance',
            ),
            const SizedBox(height: AppSpace.xxl),
            if (vm.isFirstLoad)
              ..._loading()
            else if (vm.error != null && !vm.hasActivity)
              EmptyState.error(
                title: 'Couldn\'t load attendance',
                message: vm.error!,
                onRetry: vm.load,
              )
            else ...[
              FadeSlideIn(child: _ClockCard(vm: vm)),
              const SizedBox(height: AppSpace.lg),
              FadeSlideIn.indexed(1, child: _SummaryCard(vm: vm)),
              const SizedBox(height: AppSpace.xxl),
              FadeSlideIn.indexed(2, child: _Timeline(logs: vm.logs)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _loading() => const [
    SkeletonBox(height: 260, radius: AppRadius.xl),
    SizedBox(height: AppSpace.lg),
    SkeletonBox(height: 84, radius: AppRadius.lg),
    SizedBox(height: AppSpace.xxl),
    SkeletonBox(height: 140, radius: AppRadius.lg),
  ];
}

// ── Clock ───────────────────────────────────────────────────────────────────

class _ClockCard extends StatelessWidget {
  final AttendanceViewModel vm;
  const _ClockCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isIn = vm.isCheckedIn;
    final since = vm.lastEventTime;

    final status = isIn
        ? 'Checked in'
        : vm.hasActivity
        ? 'Checked out'
        : 'Not checked in';
    final caption = since == null
        ? 'Check in to start tracking your day'
        : isIn
        ? 'since ${formatClock(since)}'
        : 'at ${formatClock(since)}';

    return HeroCard(
      color: isIn ? p.success : null,
      padding: const EdgeInsets.all(AppSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isIn
                    ? const LiveDot(color: Colors.white)
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white38,
                        ),
                      ),
                const SizedBox(width: AppSpace.sm),
                Flexible(
                  child: Text(
                    since == null ? status : '$status $caption',
                    style: context.text.labelMedium?.copyWith(color: p.onHero),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xxl),
          Text(
            'Worked today',
            style: context.text.bodyMedium?.copyWith(color: p.onHeroMuted),
          ),
          const SizedBox(height: AppSpace.sm),
          Ticking(
            active: isIn,
            builder: (_) => FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatTimer(vm.workedToday),
                style: context.text.displayMedium?.copyWith(
                  color: p.onHero,
                  fontFeatures: tabularFigures,
                ),
              ),
            ),
          ),
          if (since == null) ...[
            const SizedBox(height: AppSpace.sm),
            Text(
              caption,
              style: context.text.bodyMedium?.copyWith(color: p.onHeroMuted),
            ),
          ],
          const SizedBox(height: AppSpace.xxl),
          AppButton(
            key: ValueKey(isIn),
            label: isIn ? 'Check out' : 'Check in',
            icon: isIn ? Icons.logout_rounded : Icons.login_rounded,
            variant: isIn ? AppButtonVariant.inverse : AppButtonVariant.primary,
            loading: vm.isSubmitting,
            onPressed: () => toggleAttendance(context),
          ),
        ],
      ),
    );
  }
}

// ── Summary ─────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final AttendanceViewModel vm;
  const _SummaryCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final firstIn = vm.firstCheckIn;
    final lastOut = vm.lastCheckOut;

    Widget divider() => Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      color: p.border,
    );

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _Stat(
              label: 'First in',
              value: firstIn != null ? formatClock(firstIn) : '—',
              icon: Icons.login_rounded,
              color: p.success,
            ),
            divider(),
            _Stat(
              label: 'Last out',
              value: lastOut != null ? formatClock(lastOut) : '—',
              icon: Icons.logout_rounded,
              color: p.danger,
            ),
            divider(),
            _Stat(
              label: 'Sessions',
              value: '${vm.sessionCount}',
              icon: Icons.repeat_rounded,
              color: p.info,
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpace.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.text.titleMedium?.copyWith(
                fontFeatures: tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final List<CheckinStatusModel> logs;
  const _Timeline({required this.logs});

  @override
  Widget build(BuildContext context) {
    final entries = logs.reversed.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Today\'s activity',
          trailing: entries.isEmpty
              ? null
              : Text(
                  '${entries.length} event${entries.length == 1 ? '' : 's'}',
                  style: context.text.labelMedium,
                ),
        ),
        if (entries.isEmpty)
          const InlineEmpty(
            'No activity yet today. Your check-ins and check-outs will '
            'appear here.',
            icon: Icons.event_note_outlined,
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: AppSpace.sm,
            ),
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++)
                  _TimelineRow(
                    log: entries[i],
                    isFirst: i == 0,
                    isLast: i == entries.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final CheckinStatusModel log;
  final bool isFirst;
  final bool isLast;
  const _TimelineRow({
    required this.log,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isIn = log.logType.toUpperCase() == 'IN';
    final t = DateTime.tryParse(log.time);
    final color = isIn ? p.success : p.danger;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: isFirst ? Colors.transparent : p.border,
              ),
              IconBadge(
                icon: isIn ? Icons.login_rounded : Icons.logout_rounded,
                color: color,
                background: isIn ? p.successSoft : p.dangerSoft,
                size: 34,
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : p.border,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isIn ? 'Checked in' : 'Checked out',
                    style: context.text.titleSmall,
                  ),
                  if (isFirst) ...[
                    const SizedBox(height: 2),
                    Text('Latest', style: context.text.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          Center(
            child: Text(
              t != null ? formatClock(t) : '—',
              style: context.text.titleSmall?.copyWith(
                color: p.textSecondary,
                fontFeatures: tabularFigures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
