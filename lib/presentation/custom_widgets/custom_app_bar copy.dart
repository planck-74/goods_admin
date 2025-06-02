import 'package:flutter/material.dart';

PreferredSize customAppBar(BuildContext context, Widget child) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(56.0), // Standard AppBar height
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor, // Gradient start color
            const Color.fromARGB(255, 75, 6, 1), // Gradient end color
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        backgroundColor:
            Colors.transparent, // Set to transparent to show the gradient

        title: child,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
    ),
  );
}
