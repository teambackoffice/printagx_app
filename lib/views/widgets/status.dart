import 'package:flutter/material.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/views/widgets/live.dart';

/// Visual treatment for a job status ([JobWork.customJobStatus] vocabulary).
class StatusStyle {
  final String label;
  final Color color;
  final Color background;
  final IconData icon;
  const StatusStyle(this.label, this.color, this.background, this.icon);

  bool get isLive => label == 'In Progress';

  static StatusStyle of(BuildContext context, String status) {
    final p = context.palette;
    return switch (status) {
      'In Progress' => StatusStyle(
        'In Progress',
        p.primary,
        p.primarySoft,
        Icons.play_circle_fill_rounded,
      ),
      'Stopped' => StatusStyle(
        'Paused',
        p.warning,
        p.warningSoft,
        Icons.pause_circle_filled_rounded,
      ),
      'Completed' => StatusStyle(
        'Completed',
        p.success,
        p.successSoft,
        Icons.check_circle_rounded,
      ),
      _ => StatusStyle(
        'To Do',
        p.info,
        p.infoSoft,
        Icons.radio_button_unchecked_rounded,
      ),
    };
  }
}

class StatusPill extends StatelessWidget {
  final String status;
  final bool dense;
  const StatusPill({super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final s = StatusStyle.of(context, status);
    return AnimatedContainer(
      duration: AppDurations.normal,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: s.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          s.isLive
              ? LiveDot(color: s.color, size: 6)
              : Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
          const SizedBox(width: 6),
          Text(
            s.label,
            style: TextStyle(
              color: s.color,
              fontSize: dense ? 11.5 : 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
