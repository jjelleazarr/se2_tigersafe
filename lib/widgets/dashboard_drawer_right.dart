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
                  Icons.notifications,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(width: 18),
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Colors.white,
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