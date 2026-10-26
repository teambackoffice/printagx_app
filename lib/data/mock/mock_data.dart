import 'package:printagx_app/data/models/job_work.dart';

/// Local sample data used by the mock repositories in place of the backend.

/// Simulated network latency.
const Duration mockDelay = Duration(milliseconds: 600);

String _date(int daysAgo) => DateTime.now()
    .subtract(Duration(days: daysAgo))
    .toIso8601String()
    .substring(0, 10);

Map<String, dynamic> _job({
  required String name,
  required String jobOrder,
  required String salesOrder,
  required String customer,
  required String operation,
  required String serviceType,
  required String jobStatus,
  required int daysAgo,
  required List<Map<String, dynamic>> items,
  required List<String> employees,
  List<Duration> loggedSessions = const [],
}) {
  final created = DateTime.now()
      .subtract(Duration(days: daysAgo))
      .toIso8601String();
  return {
    "name": name,
    "creation": created,
    "modified": created,
    "job_order": jobOrder,
    "custom_sales_order_number": salesOrder,
    "operation": operation,
    "posting_date": _date(daysAgo),
    "customer": customer,
    "custom_customer_name": customer,
    "status": jobStatus == 'Completed' ? 'Completed' : 'Open',
    "custom_job_status": jobStatus,
    "custom_service_type": serviceType,
    "time_logs": [
      for (final d in loggedSessions)
        {
          "from_time": DateTime.parse(created).toIso8601String(),
          "to_time": DateTime.parse(created).add(d).toIso8601String(),
          "time_in_mins": d.inMinutes,
        },
    ],
    "custom_employees": [
      for (final e in employees)
        {"creation": created, "modified": created, "name1": e, "employees": e},
    ],
    "custom_items": [
      for (final i in items) {"creation": created, "modified": created, ...i},
    ],
  };
}

List<JobWork> buildMockJobs() => JobWorkResponse.fromJson({
  "message": [
    _job(
      name: "JW-0001",
      jobOrder: "JO-2026-0142",
      salesOrder: "SO-2026-0318",
      customer: "Blue Lagoon Cafe",
      operation: "Designing",
      serviceType: "Flex Printing",
      jobStatus: "Open",
      daysAgo: 0,
      items: [
        {"item_name": "Shop Front Banner", "copies": 2, "design_cost": 1500},
        {"item_name": "Menu Standee", "copies": 4, "design_cost": 800},
      ],
      employees: ["Arjun K"],
    ),
    _job(
      name: "JW-0002",
      jobOrder: "JO-2026-0139",
      salesOrder: "SO-2026-0311",
      customer: "Green Valley School",
      operation: "Printing",
      serviceType: "Vinyl Printing",
      jobStatus: "Stopped",
      daysAgo: 1,
      items: [
        {"item_name": "Annual Day Backdrop", "copies": 1, "design_cost": 2500},
      ],
      employees: ["Rahul M", "Fathima S"],
      loggedSessions: [Duration(hours: 1, minutes: 25)],
    ),
    _job(
      name: "JW-0003",
      jobOrder: "JO-2026-0131",
      salesOrder: "SO-2026-0297",
      customer: "Metro Textiles",
      operation: "Finishing",
      serviceType: "Screen Printing",
      jobStatus: "Completed",
      daysAgo: 3,
      items: [
        {"item_name": "Brand T-Shirts", "copies": 120, "design_cost": 3000},
      ],
      employees: ["Nihal P"],
      loggedSessions: [Duration(hours: 3, minutes: 10)],
    ),
  ],
}).message;
