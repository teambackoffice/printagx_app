import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/utils/formatters.dart';
import 'package:printagx_app/viewmodels/attendance_view_model.dart';
import 'package:printagx_app/views/widgets/common.dart';

/// Checks in, or asks for confirmation and checks out. Shared by the Today
/// dashboard and the Attendance tab.
Future<void> toggleAttendance(BuildContext context) async {
  final vm = context.read<AttendanceViewModel>();
  if (vm.isCheckedIn) {
    final ok = await confirmAction(
      context,
      title: 'Check out now?',
      message:
          'Your session will end at ${formatClock(DateTime.now())}. '
          'You can check in again later today.',
      confirmLabel: 'Check out',
      icon: Icons.logout_rounded,
      tone: ConfirmTone.danger,
    );
    if (!ok || !context.mounted) return;
  }

  try {
    final message = await vm.toggle();
    if (context.mounted) showAppSnack(context, message);
  } catch (e) {
    if (context.mounted) showAppSnack(context, e.toString(), error: true);
  }
}
