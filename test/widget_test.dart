import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:now/main.dart';
import 'package:now/login_page.dart';
import 'package:now/signup_page.dart';
import 'package:now/home_page.dart';
import 'package:now/alerts_page.dart';
import 'package:now/offline_alerts_page.dart';
import 'package:now/basic_needs_page.dart';
import 'package:now/volunteer_details_page.dart';
import 'package:now/volunteers_page.dart';
import 'package:now/emergency_contacts_page.dart';
import 'package:now/safety_status_page.dart';
import 'package:now/user_list_page.dart';
import 'package:now/user_details_page.dart';
import 'package:now/first_aid_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase before any widget test
    await Firebase.initializeApp();
  });

  testWidgets('Full app navigation test with Firebase initialized', (WidgetTester tester) async {
    await tester.pumpWidget(EmergencyContactApp());

    // 1. Verify Login Page appears
    expect(find.byType(LoginPage), findsOneWidget);

    // 2. Tap "Sign Up" if it exists
    final signUpButton = find.text('Sign Up');
    if (signUpButton.evaluate().isNotEmpty) {
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();
      expect(find.byType(SignUpPage), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    // 3. Simulate navigation to each named route
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    final routeWidgetMap = {
      '/home': HomePage,
      '/alerts': AlertsPage,
      '/offline_alerts': OfflineAlertPage,
      '/needs': BasicNeedsPage,
      '/volunteer': VolunteerDetailsPage,
      '/volunteers': VolunteersPage,
      '/contacts': EmergencyContactsPage,
      '/safety': SafetyStatusPage,
      '/user_list': UserListPage,
      '/user_details': UserDetailsPage,
      '/first_aid': FirstAidPage,
    };

    for (final route in routeWidgetMap.entries) {
      navigator.pushNamed(route.key);
      await tester.pumpAndSettle();
      expect(find.byType(route.value), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
}
