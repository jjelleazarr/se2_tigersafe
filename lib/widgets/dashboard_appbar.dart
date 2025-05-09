import 'package:flutter/material.dart';

class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: const Color(0xFFFEC00F), // Color for the icons of the side drawers
      title: SizedBox(
        height: kToolbarHeight,
        child: Center(
          child: Image.asset('assets/UST_LOGO_NO_TEXT.png'),
        ),
      ),
      backgroundColor: Colors.black,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

