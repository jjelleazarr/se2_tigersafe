import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:se2_tigersafe/screens/mobile/dashboard.dart';
import 'package:se2_tigersafe/screens/mobile/reports_list.dart';
import 'core/firebase_options.dart';
import 'screens/mobile/login_screen.dart';
import 'screens/web/login_screen.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print("Firebase Initialized Successfully!");
  

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
        useMaterial3: true, //no need for this, this is already default
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      home: getInitialScreen(),
    );
  }

  Widget getInitialScreen() {
    //if (kIsWeb) {
      //return const WebLoginScreen();
    //} else {
      return DashboardScreen();
    }
  }
//}
