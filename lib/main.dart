import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se2_tigersafe/screens/web/incident_dashboard.dart';
import 'package:se2_tigersafe/models/verification_requests_collection.dart';
import 'core/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
import 'package:se2_tigersafe/screens/web/report_logging_dashboard.dart';
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
import 'package:se2_tigersafe/screens/web/report_logging.dart';
import 'package:se2_tigersafe/screens/edit_profile_screen.dart';

Future<bool> isUserAuthorized(String uid, List<String> allowedRoles) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (!doc.exists) return false;
  final roles = List<String>.from(doc['roles'] ?? []);
  return roles.any((role) => allowedRoles.contains(role));
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Handling a background message: ${message.messageId}');
}

Future<void> saveFcmToken() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'fcm_token': token,
    });
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  if (notification != null) {
    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class FCMDebugScreen extends StatefulWidget {
  @override
  State<FCMDebugScreen> createState() => _FCMDebugScreenState();
}

class _FCMDebugScreenState extends State<FCMDebugScreen> {
  String? _fcmToken;
  String _permissionStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      setState(() {
        _permissionStatus = settings.authorizationStatus.toString();
      });
      print('User granted permission: ${settings.authorizationStatus}');

      String? token = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $token');
      setState(() {
        _fcmToken = token;
      });
      // Save token to Firestore for the logged-in user
      await saveFcmToken();
      // Listen for token refresh and update Firestore
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        await saveFcmToken();
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received a message in the foreground!');
        showLocalNotification(message);
        if (message.notification != null) {
          print('Notification title: [32m${message.notification!.title}[0m');
          print('Notification body: [32m${message.notification!.body}[0m');
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from notification!');
      });
    } catch (e) {
      print('Error initializing FCM: $e');
      setState(() {
        _permissionStatus = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('TigerSafe FCM Debug')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Notification Permission: $_permissionStatus'),
            const SizedBox(height: 16),
            SelectableText(
              _fcmToken != null
                  ? 'Your FCM Token:\n$_fcmToken\n\nSend a test notification from the Firebase Console!'
                  : 'Fetching FCM token...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _fcmToken;
  String _permissionStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initFCM();
  }

  Future<void> _initFCM() async {
    try {
      // Request notification permissions (web & iOS)
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      setState(() {
        _permissionStatus = settings.authorizationStatus.toString();
      });
      print('User granted permission: ${settings.authorizationStatus}');

      // Get the FCM token
      String? token = await FirebaseMessaging.instance.getToken();
      print('FCM Token: $token');
      setState(() {
        _fcmToken = token;
      });
      // Save token to Firestore for the logged-in user
      await saveFcmToken();
      // Listen for token refresh and update Firestore
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        await saveFcmToken();
      });

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Received a message in the foreground!');
        
        // Handle verification notifications
        if (message.data['type'] == 'verification') {
          final status = message.data['status'];
          final requestType = message.data['requestType'];
          
          // Show local notification
          showLocalNotification(RemoteMessage(
            notification: RemoteNotification(
              title: 'Verification Request $status',
              body: 'Your $requestType verification request has been $status',
            ),
          ));
        } else {
          // Show other notifications as is
          showLocalNotification(message);
        }
      });

      // Listen for messages when the app is opened from a notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from notification!');
        
        // Handle verification notification taps
        if (message.data['type'] == 'verification') {
          final status = message.data['status'];
          if (status == 'active') {
            // If approved, go to dashboard
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (status == 'rejected') {
            // If rejected, go to login
            Navigator.pushReplacementNamed(context, '/login_screen');
          }
        }
      });
    } catch (e) {
      print('Error initializing FCM: $e');
      setState(() {
        _permissionStatus = 'Error: $e';
      });
    }
  }

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
        if (settings.name == '/fcm_debug') {
          return MaterialPageRoute(builder: (_) => FCMDebugScreen());
        }
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
            return MaterialPageRoute(
              builder: (_) => FutureBuilder(
                future: resolveProtectedRoute(
                  ReportLoggingDashboardScreen(),
                  ['command_center_admin', 'command_center_operator'],
                ),
                builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                    ? snapshot.data!
                    : Scaffold(body: Center(child: CircularProgressIndicator())),
              ),
            );
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
          case '/incident_create':
            return MaterialPageRoute(
              builder: (_) => FutureBuilder(
                future: resolveProtectedRoute(
                  ReportLoggingScreen(),
                  ['command_center_admin', 'command_center_operator'],
                ),
                builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
                    ? snapshot.data!
                    : Scaffold(body: Center(child: CircularProgressIndicator())),
              ),
            );
          case '/edit_profile':
            if (user == null) {
              return MaterialPageRoute(
                builder: (_) => kIsWeb ? WebLoginScreen() : MobileLoginScreen(),
              );
            } else {
              return MaterialPageRoute(
                builder: (_) => EditProfileScreen(),
              );
            }
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