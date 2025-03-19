import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Import screens
import 'package:se2_tigersafe/screens/mobile/login_screen.dart';
import 'package:se2_tigersafe/screens/mobile/dashboard.dart';
import 'package:se2_tigersafe/screens/mobile/reports_list.dart';

import 'package:se2_tigersafe/screens/web/login_screen.dart';
import 'package:se2_tigersafe/screens/web/dashboard.dart';
import 'package:se2_tigersafe/screens/web/incident_report.dart';

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
              //'/dashboard': (context) => WebDashboardScreen(),
              //'/incident_report': (context) => WebIncidentReportScreen(),
            }
          : {
              // Mobile Routing
              '/': (context) => MobileLoginScreen(),
              //'/dashboard': (context) => DashboardScreen(), 
              '/reports': (context) => ReportsListScreen(),
            },
    );
  }
}
