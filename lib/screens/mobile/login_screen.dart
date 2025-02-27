import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/widgets_style.dart';
import 'package:se2_tigersafe/controllers/login_controller.dart';
import 'package:se2_tigersafe/controllers/users_controller.dart';
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
      print("ID: $username, Password: $password");

      try {
        UserCredential? userCredential = await _loginController
            .loginWithUsernamePassword(username, password, context);

        if (userCredential != null) {
          // Login successful
          print("Login Successful: ${userCredential.user?.uid}");
          // Navigate to the next screen
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          // Login failed
          print("Login Failed");
        }
      } catch (e) {
        // Handle any unexpected errors
        print("Error during login: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occured.")),
        );
      }
    }
  }

  void _googleSignIn() async {
    try {
      UserCredential? userCredential =
          await _loginController.loginWithGoogle(context);

      if (userCredential != null) {
        // Google Sign-in successful
        print("Google Sign-in Successful: ${userCredential.user?.uid}");

        // Check if the user profile exists, if not, navigate to profile setup
        final userDoc = await _userController.getUser(userCredential.user!.uid);
        if (userDoc == null) {
          // Navigate to profile setup, and pass the user id
          Navigator.pushNamed(context, '/edit_profile.dart',
                  arguments: userCredential.user!.uid)
              .then((value) {
            // After returning from edit profile, navigate to the dashboard
            if (value != null && value == true) {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          });
        } else {
          // Navigate to the next screen
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } else {
        // Google Sign-in failed
        print("Google Sign-in Failed");
      }
    } catch (e) {
      // Handle any unexpected errors
      print("Error during Google Sign-in: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occured.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //put this in another class since so many will use it
        title: SizedBox(
          height: kToolbarHeight,
          child: Center(child: Image.asset('assets/UST_LOGO_NO_TEXT_300.png')),
        ),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
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
                      'To access TigerSafe, please make sure you meet the following requirements:'),
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
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                      onPressed: _login, //Need to route to AccountCreateScreen
                      style: OutlinedButton.styleFrom(
                      fixedSize: const Size(170, 15), // Set width and height
                      textStyle:
                        const TextStyle(fontSize: 16, color: Colors.blue),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      ),
                      side: const BorderSide(
                        color: Colors.black), // Border color
                      ),
                      child: const Text("Create Account",
                      style: TextStyle(color: Colors.black)), // Text color
                      ),
                      OutlinedButton(
                      onPressed: _login,
                      style: OutlinedButton.styleFrom(
                      fixedSize: const Size(170, 15), // Set width and height
                      textStyle:
                        const TextStyle(fontSize: 16, color: Colors.blue),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      ),
                      side: const BorderSide(
                        color: Colors.black), // Border color
                      ),
                      child: const Text("Login",
                      style: TextStyle(color: Colors.black)), // Text color
                      ),
                    ],
                    ),

                  const SizedBox(height: 15),

                  Center(
                    child: Text(
                      'OR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Center( //Google Sign Up
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
