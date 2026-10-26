import 'package:flutter/foundation.dart';
import 'package:printagx_app/data/models/checkin_status.dart';
import 'package:printagx_app/data/repositories/attendance_repository.dart';

class AttendanceViewModel extends ChangeNotifier {
  final AttendanceRepository _repository;
  AttendanceViewModel(this._repository);

  List<CheckinStatusModel>? _logs;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  /// True until the first load completes.
  bool get isFirstLoad => _logs == null;

  /// Today's entries, oldest first.
  List<CheckinStatusModel> get logs => _logs ?? const [];
  bool get hasActivity => logs.isNotEmpty;

  bool get isCheckedIn =>
      hasActivity && logs.last.logType.toUpperCase() == 'IN';

  DateTime? get lastEventTime =>
      hasActivity ? DateTime.tryParse(logs.last.time) : null;

  DateTime? get firstCheckIn => _times('IN').firstOrNull;
  DateTime? get lastCheckOut => _times('OUT').lastOrNull;
  int get sessionCount => _times('IN').length;

  /// Total time worked today across all completed and open sessions.
  Duration get workedToday {
    var total = Duration.zero;
    DateTime? openIn;
    for (final log in logs) {
      final t = DateTime.tryParse(log.time);
      if (t == null) continue;
      if (log.logType.toUpperCase() == 'IN') {
        openIn = t;
      } else if (openIn != null) {
        total += t.difference(openIn);
        openIn = null;
      }
    }
    if (openIn != null) total += DateTime.now().difference(openIn);
    return total;
  }

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logs = await _repository.fetchToday();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Checks in or out depending on the current state.
  /// Returns a message for the user, or throws on failure.
  Future<String> toggle() async {
    final checkingOut = isCheckedIn;
    _isSubmitting = true;
    notifyListeners();

    try {
      await _repository.markCheckin(checkingOut ? 'OUT' : 'IN');
      _logs = await _repository.fetchToday();
      return checkingOut
          ? 'Checked out successfully'
          : 'Checked in successfully';
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Iterable<DateTime> _times(String type) => logs
      .where((l) => l.logType.toUpperCase() == type)
      .map((l) => DateTime.tryParse(l.time))
      .whereType<DateTime>();
}
