import 'package:flutter/material.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/UST-1.jpg', // Background image
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: const Text(
                    'MyUSTe',
                    style: TextStyle(
                      fontSize: 125,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFEC00F),
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 3,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(30.0),
                  width: 600,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border(
                      top: BorderSide(color: Color(0xFFFEC00F), width: 10),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sign In',
                        style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'To access TigerSafe, please make sure you meet the following requirements:',
                        style: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '1. UST Google Workspace Personal Account\n'
                        '2. Google Authenticator Application\n'
                        '   or\n'
                        '3. Login with a registered TigerSafe Account',
                        style: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ID Number',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const Divider(thickness: 1, color: Colors.black),
                      const SizedBox(height: 20),
                      const Text(
                        'Password',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      const Divider(thickness: 1, color: Colors.black),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot Password?',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            developer.log('Email: \${emailController.text}');
                            developer
                                .log('Password: \${passwordController.text}');
                          },
                          child: const Text('Login',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Or',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 10),
                              const Text(
                                'Sign in with Google',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: 'Need help signing in? ',
                            style: TextStyle(color: Colors.black),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
