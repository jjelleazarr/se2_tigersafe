// Contains the Drop, Dispatch, and Mark Resolved buttons
import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onDrop;
  final VoidCallback onDispatch;
  final VoidCallback onResolve;

  const ActionButtons({
    super.key,
    required this.onDrop,
    required this.onDispatch,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton("Drop", "Report", Colors.black, onDrop),
        _buildActionButton("Dispatch", "Personnel", Colors.black, onDispatch),
        _buildActionButton("Mark", "As Resolved", Colors.black, onResolve),
      ],
    );
  }

  Widget _buildActionButton(
      String boldText, String normalText, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$boldText ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber),
            ),
            TextSpan(
              text: normalText,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}