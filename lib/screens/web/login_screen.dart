import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebLoginScreen extends StatefulWidget {
  @override
  _WebLoginScreenState createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<WebLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final uid = credential.user!.uid;
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (!userDoc.exists) throw 'User data not found.';
        final data = userDoc.data()!;
        final account_status = data['account_status'];
        final role = data['roles'];

        if (account_status != 'Active') throw 'Your account has not been approved yet.';
        if (role != 'command_center_operator' && role != 'command_center_admin') {
          throw 'Only Command Center Personnel can access the web platform.';
        }

        routeToDashboard(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  void routeToDashboard(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/UST-1.jpg', fit: BoxFit.cover),
          ),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 1000;

                Widget tigerSafeTitle = Padding(
                  padding: const EdgeInsets.only(bottom: 30, right: 20),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 75,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(offset: Offset(2, 2), blurRadius: 3, color: Colors.black45)],
                      ),
                      children: [
                        TextSpan(text: 'Tiger', style: TextStyle(color: Color(0xFFFEC00F))),
                        TextSpan(text: 'Safe', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                );

                Widget loginForm = Container(
                  width: 450,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border(top: BorderSide(color: Color(0xFFFEC00F), width: 10)),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sign In', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text('To access TigerSafe, please ensure:'),
                        const SizedBox(height: 10),
                        const Text(
                          '1. UST Google Workspace Personal Account\n'
                          '2. Google Authenticator Application\n'
                          '3. Login with a registered TigerSafe Account',
                        ),
                        const SizedBox(height: 20),
                        const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            hintText: "Enter Email",
                            border: UnderlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter your email' : null,
                        ),
                        const SizedBox(height: 20),
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: "Enter Password",
                            border: UnderlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.isEmpty ? 'Please enter your password' : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {}, // TODO: Implement forgot password
                            child: const Text('Forgot Password?', style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _handleLogin,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(color: Colors.black, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              text: 'Need help signing in? ',
                              children: [
                                TextSpan(
                                  text: 'Learn More',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                return isWide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          tigerSafeTitle,
                          loginForm,
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          tigerSafeTitle,
                          loginForm,
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}
