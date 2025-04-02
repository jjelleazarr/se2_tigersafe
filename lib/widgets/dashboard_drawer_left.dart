import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:se2_tigersafe/screens/mobile/reports_list.dart';

class DashboardDrawerLeft extends StatelessWidget {
  const DashboardDrawerLeft({super.key, required this.onSelectScreen});

  final void Function(String identifier) onSelectScreen;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login_screen');
  }

  @override
  Widget build(context) {
    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.black,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(width: 18),
                Text(
                  'Max Verstappen',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading:
            const Icon(Icons.account_box, size: 26, color: Colors.white),
            title: Text(
              'My Account',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/profile_screen');
            },
          ),
          ListTile(
            leading:
            const Icon(Icons.assignment, size: 26, color: Colors.white),
            title: Text(
              'Your Reports',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            onTap: () {
              Navigator.of(context).pushReplacementNamed('/reports_list');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, size: 26, color: Colors.white),
            title: Text(
              'Logout',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            onTap: () {
              _logout(context);
            },
          ),
        ],
      ),
    );
  }
}