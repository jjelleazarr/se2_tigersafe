import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/widgets_style.dart';
import 'package:se2_tigersafe/controllers/login_controller.dart';
import 'package:se2_tigersafe/controllers/users_controller.dart';
import 'package:se2_tigersafe/controllers/verification_requests_controller.dart';
import 'package:sign_in_button/sign_in_button.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identificationController = TextEditingController();
  final _passwordController = TextEditingController();
  final LoginController _loginController = LoginController();
  final UserController _userController = UserController();
  final VerificationRequestsController _verificationController = VerificationRequestsController();

  @override
  void dispose() {
    _identificationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      String username = _identificationController.text;
      String password = _passwordController.text;

      try {
        UserCredential? userCredential = await _loginController
            .loginWithUsernamePassword(username, password, context);

        if (userCredential != null) {
          final user = userCredential.user;
          if (user == null) return;

          final userDoc = await _userController.getUser(user.uid);

          if (userDoc != null) {
            final roles = userDoc.roles;
            final accountStatus = userDoc.accountStatus;

            if (accountStatus == 'Active') {
              final List<String> roles = List<String>.from(userDoc.roles);
              if (roles.contains('emergency_response_team')) {
                Navigator.pushReplacementNamed(context, '/ert_dashboard');
              } else {
                Navigator.pushReplacementNamed(context, '/dashboard');
              }
              return;
            } else {
              Navigator.pushReplacementNamed(context, '/account_verification');
              return;
            }
          }

          final verificationRequest = await _verificationController.getRequestByUid(user.uid);

          if (verificationRequest != null) {
            Navigator.pushReplacementNamed(context, '/account_verification');
          } else {
            Navigator.pushReplacementNamed(context, '/profile_setup', arguments: user.uid);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred.")),
        );
      }
    }
  }

  void _googleSignIn() async {
    try {
      UserCredential? userCredential = await _loginController.loginWithGoogle(context);
      if (userCredential == null) return;

      final user = userCredential.user;
      if (user == null) return;

      final userDoc = await _userController.getUser(user.uid);

      if (userDoc != null) {
        final accountStatus = userDoc.accountStatus;
        final roles = userDoc.roles;

        if (accountStatus == 'Active') {
          final List<String> roles = List<String>.from(userDoc.roles);
          if (roles.contains('emergency_response_team')) {
            Navigator.pushReplacementNamed(context, '/ert_dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          Navigator.pushReplacementNamed(context, '/account_verification');
        }
        return;
      }

      final verificationRequest = await _verificationController.getRequestByUid(user.uid);

      if (verificationRequest != null) {
        Navigator.pushReplacementNamed(context, '/account_verification');
      } else {
        Navigator.pushReplacementNamed(context, '/profile_setup', arguments: user.uid);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          height: kToolbarHeight,
          child: Center(child: Image.asset('assets/UST_LOGO_NO_TEXT.png')),
        ),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Image.asset('assets/UST_LOGO_WITH_TEXT_300.png')),
                  const SizedBox(height: 40),
                  AppWidgets.loginTextContainer('To access TigerSafe, please make sure you meet the following requirements:'),
                  const SizedBox(height: 10),
                  AppWidgets.loginTextContainer('1. UST Google Workspace Personal Account'),
                  const SizedBox(height: 20),
                  AppWidgets.loginTextContainer('2. Google Authenticator Application \nor\n1. Login with a registered TigerSafe Account'),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextFormField(
                      controller: _identificationController,
                      decoration: const InputDecoration(
                        labelText: 'UST Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your UST email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: OutlinedButton(
                      onPressed: _login,
                      style: OutlinedButton.styleFrom(
                        fixedSize: const Size(215, 15),
                        textStyle: const TextStyle(fontSize: 16, color: Colors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        side: const BorderSide(color: Colors.black),
                      ),
                      child: const Text("Login", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(child: Text('OR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const SizedBox(height: 15),
                  Center(
                    child: SignInButton(
                      Buttons.google,
                      text: "Sign up with Google",
                      onPressed: _googleSignIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
