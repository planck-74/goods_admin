import 'package:flutter/material.dart';

PreferredSize customAppBar(BuildContext context, Widget child) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(56.0),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            const Color.fromARGB(255, 75, 6, 1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        title: child,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
    ),
  );
}
