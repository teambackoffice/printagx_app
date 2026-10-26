import 'package:flutter_test/flutter_test.dart';
import 'package:printagx_app/data/repositories/attendance_repository.dart';
import 'package:printagx_app/data/repositories/auth_repository.dart';
import 'package:printagx_app/data/repositories/job_repository.dart';
import 'package:printagx_app/viewmodels/attendance_view_model.dart';
import 'package:printagx_app/viewmodels/auth_view_model.dart';
import 'package:printagx_app/viewmodels/job_detail_view_model.dart';
import 'package:printagx_app/viewmodels/job_list_view_model.dart';

void main() {
  test('AuthViewModel logs in and out', () async {
    final vm = AuthViewModel(MockAuthRepository());
    expect(await vm.login('', ''), isFalse);
    expect(vm.error, isNotNull);

    expect(await vm.login('najath@shop.com', 'secret1'), isTrue);
    expect(vm.isLoggedIn, isTrue);
    expect(vm.fullName, 'Najath');

    expect(await vm.logout(), isTrue);
    expect(vm.isLoggedIn, isFalse);
  });

  test('JobListViewModel filters, searches and sorts', () async {
    final vm = JobListViewModel(MockJobRepository());
    await vm.load();
    expect(vm.countFor('All'), 3);

    // Paused work is listed before untouched and completed jobs.
    expect(vm.visibleJobs.map((j) => j.customJobStatus).toList(), [
      'Stopped',
      'Open',
      'Completed',
    ]);

    vm.setFilter('Completed');
    expect(vm.visibleJobs.single.jobOrder, 'JO-2026-0131');

    vm
      ..setFilter('All')
      ..setQuery('lagoon');
    expect(vm.visibleJobs.single.customCustomerName, 'Blue Lagoon Cafe');

    // Dashboard views ignore the list's filter and search.
    expect(vm.openJobs, hasLength(2));
    expect(vm.currentJob?.customJobStatus, 'Stopped');
    expect(vm.hasRunningJob, isFalse);
  });

  test('JobDetailViewModel runs start → pause → resume → complete', () async {
    final repo = MockJobRepository();
    final job = (await repo.fetchAssignedJobs()).firstWhere(
      (j) => j.customJobStatus == 'Open',
    );
    final vm = JobDetailViewModel(repo, job);
    expect(vm.status, JobWorkStatus.idle);

    await vm.start();
    expect(vm.status, JobWorkStatus.running);
    expect(vm.activeSince, isNotNull);
    expect(job.customJobStatus, 'In Progress');

    await vm.pause();
    expect(vm.status, JobWorkStatus.stopped);
    expect(vm.activeSince, isNull);

    await vm.resume();
    await vm.complete();
    expect(vm.status, JobWorkStatus.completed);
    expect(vm.timeLogs, hasLength(2));
    expect(job.isCompleted, isTrue);
  });

  test('AttendanceViewModel toggles check-in state', () async {
    final vm = AttendanceViewModel(MockAttendanceRepository());
    await vm.load();
    expect(vm.isCheckedIn, isFalse);
    expect(vm.hasActivity, isFalse);

    expect(await vm.toggle(), 'Checked in successfully');
    expect(vm.isCheckedIn, isTrue);
    expect(vm.sessionCount, 1);

    expect(await vm.toggle(), 'Checked out successfully');
    expect(vm.isCheckedIn, isFalse);
    expect(vm.lastCheckOut, isNotNull);
  });
}
