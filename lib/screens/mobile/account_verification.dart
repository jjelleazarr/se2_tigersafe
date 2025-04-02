import 'package:flutter/material.dart';
import 'package:se2_tigersafe/screens/mobile/login_screen.dart';
import 'package:se2_tigersafe/widgets/footer.dart';

class AccountVerification extends StatelessWidget {
  const AccountVerification({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => const MobileLoginScreen()),
            );
          },
        ),
        title: const Text(
          'Reports',
          style: TextStyle(color: Color(0xFFFEC00F), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Expanded to take up remaining space, ensuring footer stays at the bottom
          Expanded(
            child: Center(
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Verification Icon
                    const Icon(Icons.phone_callback, size: 50, color: Colors.amber),

                    const SizedBox(height: 10),

                    // Title
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                        children: [
                          TextSpan(
                            text: "Account ",
                            style: TextStyle(color: Colors.amber), // Yellow "Account"
                          ),
                          TextSpan(
                            text: "Verification in Progress",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Verification Message
                    const Text(
                      "Your Account is currently being verified.\n\nPlease Check Back Later\n\nThank You For Your Patience",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),

                    const SizedBox(height: 20),

                    // Learn More Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.all(8),
                        ),
                        onPressed: () {
                          // Handle Learn More Click (e.g., open a help page)
                        },
                        child: const Text(
                          "Learn more",
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer always stays at the bottom
          const Footer(),
        ],
      ),
    );
  }
}