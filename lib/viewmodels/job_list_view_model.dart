import 'package:flutter/foundation.dart';
import 'package:printagx_app/data/models/job_work.dart';
import 'package:printagx_app/data/repositories/job_repository.dart';

class JobListViewModel extends ChangeNotifier {
  final JobRepository _repository;
  JobListViewModel(this._repository);

  static const filters = ['All', 'Open', 'In Progress', 'Stopped', 'Completed'];
  static const _statusOrder = ['In Progress', 'Stopped', 'Open', 'Completed'];

  List<JobWork>? _jobs;
  bool _isLoading = false;
  String? _error;
  String _filter = 'All';
  String _query = '';

  /// Null until the first load completes.
  List<JobWork>? get jobs => _jobs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filter => _filter;
  String get query => _query;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _repository.fetchAssignedJobs();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  void setQuery(String value) {
    final q = value.trim();
    if (q == _query) return;
    _query = q;
    notifyListeners();
  }

  int countFor(String status) {
    final jobs = _jobs ?? const <JobWork>[];
    if (status == 'All') return jobs.length;
    return jobs.where((j) => j.customJobStatus == status).length;
  }

  /// Jobs matching the current filter and search, active work first.
  List<JobWork> get visibleJobs => _sorted(
    (_jobs ?? const <JobWork>[]).where(
      (j) =>
          (_filter == 'All' || j.customJobStatus == _filter) &&
          _matchesQuery(j),
    ),
  );

  /// Unfinished jobs regardless of filter/search, active work first.
  List<JobWork> get openJobs =>
      _sorted((_jobs ?? const <JobWork>[]).where((j) => !j.isCompleted));

  /// The job being timed right now, or else the most recently paused one.
  JobWork? get currentJob {
    final open = openJobs;
    return open.where((j) => j.activeSince != null).firstOrNull ??
        open.where((j) => j.customJobStatus == 'Stopped').firstOrNull;
  }

  bool get hasRunningJob =>
      (_jobs ?? const <JobWork>[]).any((j) => j.activeSince != null);

  List<JobWork> _sorted(Iterable<JobWork> jobs) {
    int rank(JobWork j) {
      final i = _statusOrder.indexOf(j.customJobStatus);
      return i == -1 ? 2 : i;
    }

    return jobs.toList()..sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : b.postingDate.compareTo(a.postingDate);
    });
  }

  bool _matchesQuery(JobWork j) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return [
      j.jobOrder,
      j.customCustomerName,
      j.customSalesOrderNumber,
      j.customServiceType,
      j.operation,
      ...j.customItems.map((i) => i.itemName),
    ].any((f) => f.toLowerCase().contains(q));
  }
}
