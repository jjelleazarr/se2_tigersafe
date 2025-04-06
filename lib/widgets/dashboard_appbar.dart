import 'package:flutter/material.dart';
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // 👇 This sets the color of the default back icon + any text
      foregroundColor: const Color(0xFFFEC00F),

      // 👇 Optional: applies to all icons specifically (if you want finer control)
      // iconTheme: const IconThemeData(color: Color(0xFFFEC00F)),

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

