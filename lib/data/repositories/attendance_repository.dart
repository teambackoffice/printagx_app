import 'package:printagx_app/data/mock/mock_data.dart';
import 'package:printagx_app/data/models/checkin_status.dart';

abstract class AttendanceRepository {
  /// Today's check-in/out entries, oldest first.
  Future<List<CheckinStatusModel>> fetchToday();

  /// [logType] is 'IN' or 'OUT'.
  Future<CheckinStatusModel> markCheckin(String logType);
}

class MockAttendanceRepository implements AttendanceRepository {
  final List<CheckinStatusModel> _log = [];

  @override
  Future<List<CheckinStatusModel>> fetchToday() async {
    await Future.delayed(mockDelay);
    return List.unmodifiable(_log);
  }

  @override
  Future<CheckinStatusModel> markCheckin(String logType) async {
    await Future.delayed(mockDelay);
    final entry = CheckinStatusModel(
      status: 'success',
      employee: '',
      logType: logType,
      time: DateTime.now().toIso8601String(),
    );
    _log.add(entry);
    return entry;
  }
}
