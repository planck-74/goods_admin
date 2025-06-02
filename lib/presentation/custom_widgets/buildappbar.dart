import 'package:flutter/material.dart';

PreferredSizeWidget buildAppBar(
    {required double screenWidth,
    required double screenHeight,
    required BuildContext context,
    required String screenName,
    PreferredSize? bottom,
    Widget? child}) {
  return AppBar(
    leading: Center(
      child: Text(
        screenName,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
    actions: [
      const ImageIcon(
        AssetImage('assets/images/app_logo_black.png'),
        size: 80,
      ),
      SizedBox(
        width: screenWidth * 0.16,
      ),
      GestureDetector(child: const Icon(Icons.notifications)),
      SizedBox(
        width: screenWidth * 0.03,
      ),
      GestureDetector(child: const Icon(Icons.person)),
      SizedBox(
        width: screenWidth * 0.03,
      ),
    ],
    bottom: bottom,
  );
}
