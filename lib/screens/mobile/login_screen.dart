import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/widgets_style.dart';
import 'package:se2_tigersafe/controllers/login_controller.dart';

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

  @override
  void dispose() {
    _identificationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      _loginController.loginWithUsernamePassword(_identificationController.text, _passwordController.text, context);
      print("ID: ${_identificationController.text}, Password: ${_passwordController.text}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( //put this in another class since so many will use it 
        title: SizedBox(
          height: kToolbarHeight,
          child: Center(child: Image.asset('assets/UST_LOGO_NO_TEXT_300.png')),
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
                  Center(
                    child: Image.asset('assets/UST_LOGO_WITH_TEXT_300.png'),
                  ),
                  const SizedBox(height: 40),
                  AppWidgets.loginTextContainer(
                    'To access TigerSafe, please make sure you meet the following requirements:'
                  ),
                  const SizedBox(height: 10),
                  AppWidgets.loginTextContainer(
                    '1. UST Google Workspace Personal Account',
                  ),
                  const SizedBox(height: 20),
                  AppWidgets.loginTextContainer(
                    '2. Google Authenticator Application \nor\n1. Login with a registered TigerSafe Account',
                  ),
                  const SizedBox(height: 20),

                  // ID Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextFormField(
                      controller: _identificationController,
                      decoration: const InputDecoration(
                        labelText: 'Identification (UST Email or ID)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your UST ID or email';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true, // Hides password input
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

                  // Login Button
                  Center(
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text("Login"),
                    ),
                  ),
                  const SizedBox(height: 15),
                  AppWidgets.loginTextContainer(
                    'OR',
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text("Login"), //FOR GOOGLE AUTHENTICATION
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
