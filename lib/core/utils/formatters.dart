const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// 9:05 AM
String formatClock(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
}

/// 12 Oct 2026
String formatDate(DateTime dt) =>
    '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

/// Monday, 12 Oct
String formatLongDate(DateTime dt) =>
    '${_weekdays[dt.weekday - 1]}, ${dt.day} ${_months[dt.month - 1]}';

/// 02:15:08
String formatTimer(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

/// 2h 15m · 45m · <1m
String formatDurationShort(Duration d) {
  if (d.inMinutes < 1) return '<1m';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

String greetingFor(DateTime now) {
  if (now.hour < 12) return 'Good morning';
  if (now.hour < 17) return 'Good afternoon';
  return 'Good evening';
}

String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
  if (parts.isEmpty) return 'U';
  return parts.take(2).map((e) => e[0]).join().toUpperCase();
}
