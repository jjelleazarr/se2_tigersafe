import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/screens/web/incident_dashboard.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'core/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Mobile screens
import 'package:se2_tigersafe/screens/mobile/login_screen.dart';
import 'package:se2_tigersafe/screens/mobile/dashboard.dart';
import 'package:se2_tigersafe/screens/mobile/ert_dashboard.dart';
import 'package:se2_tigersafe/screens/mobile/reports_list.dart';
import 'package:se2_tigersafe/screens/mobile/account_create.dart';
import 'package:se2_tigersafe/screens/mobile/incident_reporting.dart';
import 'package:se2_tigersafe/screens/mobile/account_verification.dart';
import 'package:se2_tigersafe/screens/mobile/profile_setup.dart';

// Web screens
import 'package:se2_tigersafe/screens/web/login_screen.dart';
import 'package:se2_tigersafe/screens/web/dashboard.dart';
import 'package:se2_tigersafe/screens/web/emergency_personnel.dart';
import 'package:se2_tigersafe/screens/web/report_logging.dart';
import 'package:se2_tigersafe/screens/web/announcement_board.dart';
import 'package:se2_tigersafe/screens/web/announcement_form.dart';
import 'package:se2_tigersafe/screens/web/account_management.dart';
import 'package:se2_tigersafe/screens/web/manage_accounts.dart';
import 'package:se2_tigersafe/screens/web/stakeholder_verification.dart';
import 'package:se2_tigersafe/screens/web/stakeholder_verification_details.dart';
import 'package:se2_tigersafe/screens/web/stakeholder_verification_action.dart';
import 'package:se2_tigersafe/screens/web/priority_verification.dart';
import 'package:se2_tigersafe/screens/web/priority_verification_details.dart';
import 'package:se2_tigersafe/screens/web/priority_verification_action.dart';

Future<bool> isUserAuthorized(String uid, List<String> allowedRoles) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) return false;
  final roles = List<String>.from(doc['roles'] ?? []);
  return roles.any((role) => allowedRoles.contains(role));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TigerSafe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final user = FirebaseAuth.instance.currentUser;

        Future<Widget> resolveProtectedRoute(Widget screen, List<String> roles) async {
          if (user == null) return kIsWeb ? WebLoginScreen() : MobileLoginScreen();
          final authorized = await isUserAuthorized(user.uid, roles);
          return authorized ? screen : (kIsWeb ? WebLoginScreen() : MobileLoginScreen());
        }

        switch (settings.name) {
          case '/':
          case '/login_screen':
            return MaterialPageRoute(
              builder: (_) => kIsWeb ? WebLoginScreen() : MobileLoginScreen(),
            );

          // Mobile routes
          case '/account_create':
            return MaterialPageRoute(builder: (_) => AccountCreateScreen());
          case '/account_verification':
            return MaterialPageRoute(builder: (_) => AccountVerification());
          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => kIsWeb ? WebDashboardScreen() : DashboardScreen(),
            );
          case '/ert_dashboard':
            return MaterialPageRoute(builder: (_) => ERTDashboardScreen());
          case '/reports':
            return MaterialPageRoute(builder: (_) => ReportsListScreen());
          case '/profile_setup':
            return MaterialPageRoute(builder: (_) => ProfileSetupScreen());
          case '/hazard_reporting':
            return MaterialPageRoute(builder: (_) => IncidentReportingScreen());

          // Web routes with RBAC
          case '/response_teams':
            return MaterialPageRoute(builder: (_) => FutureBuilder(
              future: resolveProtectedRoute(ResponseTeamsScreen(), ['command_center_admin', 'command_center_operator']),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            ));
          case '/report_logging':
            return MaterialPageRoute(builder: (_) => FutureBuilder(
              future: resolveProtectedRoute(ReportLoggingScreen(), ['command_center_admin', 'command_center_operator']),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            ));
          case '/announcement_board':
            return MaterialPageRoute(builder: (_) => FutureBuilder(
              future: resolveProtectedRoute(AnnouncementBoardScreen(), ['command_center_admin', 'command_center_operator']),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            ));
          case '/announcement_form':
            return MaterialPageRoute(builder: (_) => FutureBuilder(
              future: resolveProtectedRoute(AnnouncementFormScreen(), ['command_center_admin', 'command_center_operator']),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            ));
          case '/account_management':
            return MaterialPageRoute(builder: (_) => FutureBuilder(
              future: resolveProtectedRoute(AccountManagementScreen(), ['command_center_admin']),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            ));
          case '/manage_accounts':
            return MaterialPageRoute(builder: (_) => FutureBuilder(
              future: resolveProtectedRoute(ManageAccountsScreen(), ['command_center_admin']),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            ));
          case '/stakeholder_verification':
            return MaterialPageRoute(builder: (_) => FutureBuilder(
              future: resolveProtectedRoute(StakeholderVerificationScreen(), ['command_center_admin', 'command_center_operator']),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            ));
          case '/priority_verification':
            return MaterialPageRoute(builder: (_) => FutureBuilder(
              future: resolveProtectedRoute(PriorityVerificationScreen(), ['command_center_admin', 'command_center_operator']),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            ));
          case '/incident_dashboard':
            return MaterialPageRoute(builder: (_) => FutureBuilder(
              future: resolveProtectedRoute(IncidentDashboardScreen(), ['command_center_admin', 'command_center_operator']),
              builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                  ? snapshot.data!
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            ));
        }

        // Verification screens (shared)
        if (settings.name == '/stakeholder_verification_details') {
          final args = settings.arguments as VerificationRequestModel;
          return MaterialPageRoute(
            builder: (_) => StakeholderVerificationDetailsScreen(request: args),
          );
        }
        if (settings.name == '/stakeholder_verification_action') {
          final args = settings.arguments as VerificationRequestModel;
          return MaterialPageRoute(
            builder: (_) => ApplicationDeniedScreen(request: args),
          );
        }
        if (settings.name == '/priority_verification_details') {
          final args = settings.arguments as VerificationRequestModel;
          return MaterialPageRoute(
            builder: (_) => PriorityVerificationDetailsScreen(request: args),
          );
        }
        if (settings.name == '/priority_verification_action') {
          final args = settings.arguments as VerificationRequestModel;
          return MaterialPageRoute(
            builder: (_) => PriorityApplicationDeniedScreen(request: args),
          );
        }

        return null;
      },
    );
  }
}
