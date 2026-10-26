import 'package:flutter/foundation.dart';
import 'package:printagx_app/data/models/job_work.dart';
import 'package:printagx_app/data/repositories/job_repository.dart';

enum JobWorkStatus { idle, running, stopped, completed }

class JobDetailViewModel extends ChangeNotifier {
  final JobRepository _repository;
  final JobWork job;

  JobDetailViewModel(this._repository, this.job) {
    _status = _deriveStatus();
  }

  late JobWorkStatus _status;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  JobWorkStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  DateTime? get activeSince => job.activeSince;
  Duration get totalTracked => job.trackedTime;

  /// Status string in the same vocabulary as [JobWork.customJobStatus].
  String get statusKey => switch (_status) {
    JobWorkStatus.running => 'In Progress',
    JobWorkStatus.stopped => 'Stopped',
    JobWorkStatus.completed => 'Completed',
    JobWorkStatus.idle => 'Open',
  };

  /// Time logs, newest first.
  List<TimeLog> get timeLogs =>
      job.timeLogs.where((l) => l.fromTime != null).toList().reversed.toList();

  Future<void> start() => _execute(
    () => _repository.startTimeLog(job),
    JobWorkStatus.running,
    'Timer started',
  );

  Future<void> pause() => _execute(
    () => _repository.stopTimeLog(job),
    JobWorkStatus.stopped,
    'Work paused',
  );

  Future<void> resume() => _execute(
    () => _repository.continueTimeLog(job),
    JobWorkStatus.running,
    'Work resumed',
  );

  Future<void> complete() => _execute(
    () => _repository.completeJob(job),
    JobWorkStatus.completed,
    'Job marked as completed',
  );

  JobWorkStatus _deriveStatus() {
    if (job.isCompleted) return JobWorkStatus.completed;
    if (job.activeSince != null || job.customJobStatus == 'In Progress') {
      return JobWorkStatus.running;
    }
    if (job.timeLogs.isNotEmpty || job.customJobStatus == 'Stopped') {
      return JobWorkStatus.stopped;
    }
    return JobWorkStatus.idle;
  }

  Future<void> _execute(
    Future<void> Function() action,
    JobWorkStatus next,
    String message,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await action();
      _status = next;
      _successMessage = message;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
