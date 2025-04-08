import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:se2_tigersafe/screens/web/incident_dashboard.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'core/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Mobile screens
import 'package:se2_tigersafe/screens/mobile/login_screen.dart';
import 'package:se2_tigersafe/screens/mobile/dashboard.dart';
import 'package:se2_tigersafe/screens/mobile/ert_dashboard.dart';
import 'package:se2_tigersafe/screens/mobile/reports_list.dart';
// import 'package:se2_tigersafe/screens/mobile/hazard_reporting.dart';
// import 'package:se2_tigersafe/screens/mobile/emergency_personnel.dart';
// import 'package:se2_tigersafe/screens/mobile/report_logging.dart';
// import 'package:se2_tigersafe/screens/mobile/announcement_board.dart';
import 'package:se2_tigersafe/screens/mobile/account_create.dart';
import 'package:se2_tigersafe/screens/mobile/incident_reporting.dart';
import 'package:se2_tigersafe/screens/mobile/account_verification.dart';
import 'package:se2_tigersafe/screens/mobile/profile_setup.dart';
// Web screens
import 'package:se2_tigersafe/screens/web/login_screen.dart';
import 'package:se2_tigersafe/screens/web/dashboard.dart';
import 'package:se2_tigersafe/screens/web/incident_report.dart';
import 'package:se2_tigersafe/screens/web/hazard_reporting.dart';
import 'package:se2_tigersafe/screens/web/emergency_personnel.dart';
import 'package:se2_tigersafe/screens/web/report_logging.dart';
import 'package:se2_tigersafe/screens/web/announcement_board.dart';
import 'package:se2_tigersafe/screens/web/create_announcement.dart';
import 'package:se2_tigersafe/screens/web/account_management.dart';
import 'package:se2_tigersafe/screens/web/manage_accounts.dart';
import 'package:se2_tigersafe/screens/web/stakeholder_verification.dart';
import 'package:se2_tigersafe/screens/web/stakeholder_verification_details.dart';
import 'package:se2_tigersafe/screens/web/stakeholder_verification_action.dart';
import 'package:se2_tigersafe/screens/web/priority_verification.dart';
import 'package:se2_tigersafe/screens/web/priority_verification_details.dart';
import 'package:se2_tigersafe/screens/web/priority_verification_action.dart';

void main() async {
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
      routes: kIsWeb
          ? {
              // Web Routing
        '/': (context) => WebLoginScreen(),
        '/dashboard': (context) => WebDashboardScreen(),
        '/incident_report': (context) => IncidentDashboardScreen(),
        // '/hazard_reporting': (context) => HazardReportingScreen(),
        '/response_teams': (context) => ResponseTeamsScreen(),
        // '/report_logging': (context) => ReportLoggingScreen(),
        '/announcement_board': (context) => AnnouncementBoardScreen(),
        '/create_announcement': (context) => CreateAnnouncementScreen(),
        '/account_management': (context) => AccountManagementScreen(),
        '/manage_accounts': (context) => ManageAccountsScreen(),
        '/stakeholder_verification': (context) => StakeholderVerificationScreen(),
        '/priority_verification': (context) => PriorityVerificationScreen(),
        '/incident_dashboard': (context) => IncidentDashboardScreen(),
            }
          : {
              // Mobile Routing
            '/': (context) => MobileLoginScreen(),
            '/login_screen': (context) => MobileLoginScreen(),
            '/account_create': (context) => AccountCreateScreen(),
            '/account_verification': (context) => AccountVerification(),
            '/dashboard': (context) => DashboardScreen(),
            '/ert_dashboard': (context) => ERTDashboardScreen(),
            '/reports': (context) => ReportsListScreen(),
            '/profile_setup': (context) => ProfileSetupScreen(),
            '/hazard_reporting': (context) => IncidentReportingScreen(),
              // '/response_teams': (context) => EmergencyPersonnelScreen(),
              // '/report_logging': (context) => ReportLoggingScreen(),
              // '/announcement_board': (context) => AnnouncementBoardScreen(),
            },

            onGenerateRoute: (settings) {
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
