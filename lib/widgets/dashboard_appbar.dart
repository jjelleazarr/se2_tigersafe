import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
     title: SizedBox(
        height: kToolbarHeight,
        child: Center(child: Image.asset('assets/UST_LOGO_NO_TEXT_300.png')),
      ),
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white, size: 30,),
        onPressed: () {
          Scaffold.of(context).openDrawer(); // Left Drawer
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_active, color: Color(0xFFFEC00F), size: 30),
          onPressed: () {
        Scaffold.of(context).openEndDrawer(); // Right Drawer
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
