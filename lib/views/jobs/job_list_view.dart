import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/core/utils/formatters.dart';
import 'package:printagx_app/data/models/job_work.dart';
import 'package:printagx_app/viewmodels/job_list_view_model.dart';
import 'package:printagx_app/views/jobs/job_detail_view.dart';
import 'package:printagx_app/views/widgets/common.dart';

/// "Jobs" tab: search, status filters and the assigned job list.
class JobListView extends StatefulWidget {
  /// One of [JobListViewModel.filters]; when null the current filter is kept.
  final String? initialFilter;
  const JobListView({super.key, this.initialFilter});

  @override
  State<JobListView> createState() => _JobListViewState();
}

class _JobListViewState extends State<JobListView> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = context.read<JobListViewModel>().query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<JobListViewModel>();
      if (widget.initialFilter != null) vm.setFilter(widget.initialFilter!);
      vm.load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JobListViewModel>();
    final p = context.palette;
    final open = vm.jobs == null ? 0 : vm.openJobs.length;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.lg,
                AppSpace.gutter,
                AppSpace.lg,
              ),
              child: Column(
                children: [
                  PageHeader(
                    title: 'Jobs',
                    subtitle: vm.jobs == null
                        ? 'Loading your assignments…'
                        : '$open open · ${vm.countFor('All')} assigned to you',
                  ),
                  const SizedBox(height: AppSpace.lg),
                  _SearchField(controller: _searchController, vm: vm),
                ],
              ),
            ),
            _FilterBar(vm: vm),
            const SizedBox(height: AppSpace.sm),
            AnimatedOpacity(
              opacity: vm.isLoading && vm.jobs != null ? 1 : 0,
              duration: AppDurations.normal,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: p.background,
              ),
            ),
            Expanded(child: _buildBody(vm)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(JobListViewModel vm) {
    if (vm.jobs == null && vm.error == null) {
      return ListView.separated(
        padding: const EdgeInsets.all(AppSpace.gutter),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
        itemBuilder: (_, _) => const _JobCardSkeleton(),
      );
    }

    if (vm.jobs == null) {
      return Center(
        child: SingleChildScrollView(
          child: EmptyState.error(
            title: 'Couldn\'t load jobs',
            message: vm.error!,
            onRetry: vm.load,
          ),
        ),
      );
    }

    final visible = vm.visibleJobs;
    final searching = vm.query.isNotEmpty;

    return RefreshIndicator(
      onRefresh: vm.load,
      child: visible.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icon: searching
                      ? Icons.search_off_rounded
                      : Icons.assignment_turned_in_outlined,
                  title: searching ? 'No matching jobs' : 'Nothing here',
                  message: searching
                      ? 'Nothing matches "${vm.query}". Try a job number, '
                            'customer or item name.'
                      : 'No jobs with this status right now.',
                  action: vm.filter == 'All' && !searching
                      ? null
                      : TextButton(
                          onPressed: () {
                            _searchController.clear();
                            vm
                              ..setQuery('')
                              ..setFilter('All');
                          },
                          child: const Text('Clear search & filters'),
                        ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.gutter,
                AppSpace.sm,
                AppSpace.gutter,
                AppSpace.xxxl,
              ),
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
              itemBuilder: (_, i) => FadeSlideIn.indexed(
                i,
                key: ValueKey(visible[i].name),
                child: _JobCard(
                  job: visible[i],
                  onTap: () => JobDetailView.open(context, visible[i]),
                ),
              ),
            ),
    );
  }
}

// ── Search & filters ────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final JobListViewModel vm;
  const _SearchField({required this.controller, required this.vm});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: vm.setQuery,
      textInputAction: TextInputAction.search,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search job, customer or item',
        prefixIcon: const Icon(Icons.search_rounded),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        suffixIcon: vm.query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.cancel_rounded, size: AppIconSize.md),
                onPressed: () {
                  controller.clear();
                  vm.setQuery('');
                },
              ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final JobListViewModel vm;
  const _FilterBar({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
        itemCount: JobListViewModel.filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (_, i) {
          final f = JobListViewModel.filters[i];
          return _FilterChip(
            label: f == 'All' ? 'All' : StatusStyle.of(context, f).label,
            count: vm.countFor(f),
            selected: f == vm.filter,
            onTap: () => vm.setFilter(f),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected
        ? (p.isDark ? AppBrand.ink : Colors.white)
        : p.textPrimary;
    final bg = selected ? p.textPrimary : p.surface;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppDurations.normal,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(14, 0, 6, 0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: selected ? bg : p.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                AnimatedContainer(
                  duration: AppDurations.normal,
                  constraints: const BoxConstraints(minWidth: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? fg.withValues(alpha: 0.16)
                        : p.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fg,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Job card ────────────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final JobWork job;
  final VoidCallback onTap;

  const _JobCard({required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final extraItems = job.customItems.length - 1;
    final running = job.activeSince != null;

    return AnimatedOpacity(
      duration: AppDurations.normal,
      opacity: job.isCompleted ? 0.72 : 1,
      child: AppCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        borderColor: running ? p.primary.withValues(alpha: 0.4) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.lg,
                AppSpace.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tag_rounded, size: 14, color: p.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          job.jobOrder,
                          style: context.text.labelMedium?.copyWith(
                            letterSpacing: 0.3,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                      ),
                      StatusPill(status: job.customJobStatus, dense: true),
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(
                    job.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleLarge?.copyWith(fontSize: 17),
                  ),
                  if (job.customCustomerName.isNotEmpty || extraItems > 0) ...[
                    const SizedBox(height: AppSpace.xs),
                    Row(
                      children: [
                        if (job.customCustomerName.isNotEmpty) ...[
                          Icon(
                            Icons.storefront_outlined,
                            size: 15,
                            color: p.textMuted,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            [
                              if (job.customCustomerName.isNotEmpty)
                                job.customCustomerName,
                              if (extraItems > 0)
                                '+$extraItems more item${extraItems > 1 ? 's' : ''}',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                10,
                AppSpace.lg,
                10,
              ),
              decoration: BoxDecoration(
                color: p.surfaceMuted.withValues(alpha: 0.55),
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpace.md,
                      runSpacing: AppSpace.xs,
                      children: [
                        if (job.customServiceType.isNotEmpty)
                          _Meta(
                            icon: Icons.print_outlined,
                            text: job.customServiceType,
                          ),
                        if (job.operation.isNotEmpty)
                          _Meta(icon: Icons.tune_rounded, text: job.operation),
                        _Meta(
                          icon: Icons.event_outlined,
                          text: formatDate(job.postingDate),
                        ),
                      ],
                    ),
                  ),
                  if (job.trackedTime > Duration.zero)
                    Ticking(
                      active: running,
                      builder: (_) => _Meta(
                        icon: running
                            ? Icons.timelapse_rounded
                            : Icons.timer_outlined,
                        text: formatDurationShort(job.trackedTime),
                        color: running ? p.primary : p.textPrimary,
                        bold: true,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final bool bold;
  const _Meta({
    required this.icon,
    required this.text,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: AppSpace.xs),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: c,
            fontFeatures: tabularFigures,
          ),
        ),
      ],
    );
  }
}

class _JobCardSkeleton extends StatelessWidget {
  const _JobCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(height: 12, width: 96),
              Spacer(),
              SkeletonBox(height: 22, width: 76, radius: AppRadius.pill),
            ],
          ),
          SizedBox(height: AppSpace.lg),
          SkeletonBox(height: 18, width: 200),
          SizedBox(height: AppSpace.sm),
          SkeletonBox(height: 12, width: 140),
          SizedBox(height: AppSpace.lg),
          SkeletonBox(height: 14),
        ],
      ),
    );
  }
}
