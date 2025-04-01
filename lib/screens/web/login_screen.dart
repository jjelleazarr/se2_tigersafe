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

        Navigator.pushReplacementNamed(context, '/dashboard');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      final uid = userCredential.user!.uid;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw 'No profile found for this Google user. You may need to register via mobile first.';
      }

      final role = userDoc['roles'];
      final status = userDoc['account_status'];

      if (status != 'Active') {
        throw 'Account is not active.';
      }

      if (role != 'command_center_operator' && role != 'command_center_admin') {
        throw 'Google login is allowed only for Command Center personnel.';
      }

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/UST-1.jpg', fit: BoxFit.cover),
          ),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Text(
                    'MyUSTe',
                    style: TextStyle(
                      fontSize: 75,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFEC00F),
                      shadows: [Shadow(offset: Offset(2, 2), blurRadius: 3, color: Colors.black45)],
                    ),
                  ),
                ),
                Container(
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
                            onPressed: () {}, // No implementation yet
                            child: const Text('Forgot Password?', style: TextStyle(color: Colors.black)),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            child: const Text('Login'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Text('Or',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _signInWithGoogle,
                            child: Text('Sign in with Google', style: TextStyle(color: Colors.black)),
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
