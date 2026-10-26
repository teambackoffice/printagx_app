import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:printagx_app/main.dart';

Future<void> settle(WidgetTester tester) async {
  // Screens contain looping animations, so pump fixed frames instead of
  // pumpAndSettle.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Bottom-nav tabs only show the active label, so tap them by key.
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(ValueKey('nav-$label')));
  await settle(tester);
}

Future<void> signIn(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pump(const Duration(seconds: 3));
  await settle(tester);
  await tester.enterText(find.byType(TextFormField).at(0), 'najath');
  await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
  await tester.tap(find.text('Sign in'));
  await settle(tester);
}

void main() {
  testWidgets('Splash leads to login page', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Login, track a job and check in', (tester) async {
    usePhoneSize(tester);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);

    // Validation blocks empty submit.
    await tester.tap(find.text('Sign in'));
    await settle(tester);
    expect(find.text('Enter your email or username'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'najath');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Sign in'));
    await settle(tester);

    expect(find.text('Najath'), findsOneWidget);
    expect(find.text('Not checked in yet'), findsOneWidget);

    // Job list and filters, via the bottom navigation.
    await tapTab(tester, 'Jobs');
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Shop Front Banner'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'metro');
    await settle(tester);
    expect(find.text('Brand T-Shirts'), findsOneWidget);
    expect(find.text('Shop Front Banner'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await settle(tester);

    // Start then pause a job.
    await tester.tap(find.text('Shop Front Banner'));
    await settle(tester);
    await tester.tap(find.text('Start work'));
    await settle(tester);
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await settle(tester);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);

    await tester.pageBack();
    await settle(tester);

    // Check in from the attendance tab.
    await tapTab(tester, 'Attendance');
    await tester.tap(find.widgetWithText(FilledButton, 'Check in'));
    await settle(tester);
    expect(find.widgetWithText(FilledButton, 'Check out'), findsOneWidget);
    expect(find.text('Checked in'), findsOneWidget);

    // The dashboard reflects the shift and the paused job.
    await tapTab(tester, 'Today');
    expect(find.text('You\'re checked in'), findsOneWidget);
    expect(find.text('Pick up where you left off'), findsOneWidget);
  });

  testWidgets('Check in from the dashboard and log out from profile', (
    tester,
  ) async {
    usePhoneSize(tester);
    await signIn(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Check in'));
    await settle(tester);
    expect(find.text('You\'re checked in'), findsOneWidget);

    await tapTab(tester, 'Profile');
    expect(find.text('EMP-0001'), findsWidgets);

    await tester.ensureVisible(find.text('Log out'));
    await settle(tester);
    await tester.tap(find.text('Log out'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await settle(tester);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Every tab renders in dark mode', (tester) async {
    usePhoneSize(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await signIn(tester);
    for (final tab in ['Jobs', 'Attendance', 'Profile', 'Today']) {
      await tapTab(tester, tab);
      expect(tester.takeException(), isNull);
    }
  });
}
