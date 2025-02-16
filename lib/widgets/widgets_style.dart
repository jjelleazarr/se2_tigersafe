import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppWidgets {
  static Widget loginTextContainer(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30), // Better padding management
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 17,
          color: Colors.black,
        ),
      ),
    );
  }
}


