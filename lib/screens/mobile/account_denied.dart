import 'package:flutter/material.dart';
import 'package:se2_tigersafe/widgets/back_button_appbar.dart';
import 'package:se2_tigersafe/widgets/footer.dart';
import 'package:se2_tigersafe/widgets/dashboard_appbar.dart';

class AccountDenied extends StatelessWidget {
  const AccountDenied({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: const BackButtonAppBar(title: "Access Denied"),
  body: Column(
    children: [
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
                const Icon(Icons.block, size: 75, color: Color(0xFFF00000)),
                const SizedBox(height: 10),
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    children: [
                      TextSpan(
                        text: "Unauthorized ",
                        style: TextStyle(color: Color(0xFFFEC00F)), 
                      ),
                      TextSpan(
                        text: "Access",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Unfortunately, Your Account has either been banned or locked.\n\nPlease Contact the TigerSafe Admin at the UST Campus Security Office for More Information",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                const SizedBox(height: 20),
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
      const Footer(),
    ],
  ),
);
  }
}