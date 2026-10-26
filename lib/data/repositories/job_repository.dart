import 'package:printagx_app/data/mock/mock_data.dart';
import 'package:printagx_app/data/models/job_work.dart';

abstract class JobRepository {
  Future<List<JobWork>> fetchAssignedJobs();

  Future<void> startTimeLog(JobWork job);
  Future<void> stopTimeLog(JobWork job);
  Future<void> continueTimeLog(JobWork job);
  Future<void> completeJob(JobWork job);
}

/// In-memory implementation that mutates the sample jobs the way the
/// backend would.
class MockJobRepository implements JobRepository {
  final List<JobWork> _jobs = buildMockJobs();

  @override
  Future<List<JobWork>> fetchAssignedJobs() async {
    await Future.delayed(mockDelay);
    return List.unmodifiable(_jobs);
  }

  @override
  Future<void> startTimeLog(JobWork job) async {
    await Future.delayed(mockDelay);
    _openSegment(job);
    job.customJobStatus = 'In Progress';
  }

  @override
  Future<void> stopTimeLog(JobWork job) async {
    await Future.delayed(mockDelay);
    _closeSegments(job);
    job.customJobStatus = 'Stopped';
  }

  @override
  Future<void> continueTimeLog(JobWork job) => startTimeLog(job);

  @override
  Future<void> completeJob(JobWork job) async {
    await Future.delayed(mockDelay);
    _closeSegments(job);
    job.customJobStatus = 'Completed';
    job.status = 'Completed';
  }

  void _openSegment(JobWork job) {
    job.timeLogs.add(
      TimeLog.fromJson({"from_time": DateTime.now().toIso8601String()}),
    );
  }

  void _closeSegments(JobWork job) {
    for (final l in job.timeLogs) {
      if (l.fromTime != null && l.toTime == null) {
        l.toTime = DateTime.now();
        l.timeInMins = l.toTime!.difference(l.fromTime!).inSeconds / 60;
      }
    }
  }
}
