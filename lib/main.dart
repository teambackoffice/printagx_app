import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printagx_app/core/theme/app_theme.dart';
import 'package:printagx_app/data/repositories/attendance_repository.dart';
import 'package:printagx_app/data/repositories/auth_repository.dart';
import 'package:printagx_app/data/repositories/job_repository.dart';
import 'package:printagx_app/viewmodels/attendance_view_model.dart';
import 'package:printagx_app/viewmodels/auth_view_model.dart';
import 'package:printagx_app/viewmodels/job_list_view_model.dart';
import 'package:printagx_app/views/splash/splash_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Repositories (swap the Mock* classes for API-backed ones) ──
        Provider<AuthRepository>(create: (_) => MockAuthRepository()),
        Provider<JobRepository>(create: (_) => MockJobRepository()),
        Provider<AttendanceRepository>(
          create: (_) => MockAttendanceRepository(),
        ),

        // ── App-wide view models ──
        ChangeNotifierProvider(
          create: (c) => AuthViewModel(c.read<AuthRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => JobListViewModel(c.read<JobRepository>()),
        ),
        ChangeNotifierProvider(
          create: (c) => AttendanceViewModel(c.read<AttendanceRepository>()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Printagx',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const SplashView(),
      ),
    );
  }
}
