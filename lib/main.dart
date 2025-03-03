import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:se2_tigersafe/screens/mobile/account_create.dart';
import 'package:se2_tigersafe/screens/mobile/dashboard.dart';
import 'package:se2_tigersafe/screens/mobile/reports_list.dart';
import 'core/firebase_options.dart';
import 'screens/mobile/login_screen.dart';
// import 'screens/web/login_screen.dart';
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
      initialRoute: '/', // This is for mobile
      routes: {
        '/': (context) => MobileLoginScreen(), // Default screen
        '/account_create': (context) => AccountCreateScreen(), // Account create screen
        '/dashboard': (context) => DashboardScreen(), // Ensure this screen exists
      },
    );
  }
}
//}
