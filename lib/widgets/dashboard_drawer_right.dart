import 'package:flutter/material.dart';

class DashboardDrawerRight extends StatelessWidget {
  const DashboardDrawerRight({super.key, required this.onSelectScreen});

  final void Function(String identifier) onSelectScreen; //Needs to change to be different from the left?

  @override
  Widget build(context){
    return
    Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          DrawerHeader(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black, 
            ),
            child: Row(
              children: [
                Icon(
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
            leading: Icon(Icons.account_box,
                size: 26, color: Colors.white),
            title: Text(
              'Accounts',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
            ),
            onTap: () {
              onSelectScreen('meals');
            },
          ),
          ListTile(
            leading: Icon(Icons.settings,
                size: 26, color: Colors.white),
            title: Text(
              'Settings',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
            ),
            onTap: () {
              onSelectScreen('meals');
            },
          ),
        ],
      ),
    );
  }
}