import 'package:flutter/material.dart';
import 'package:goods_admin/data/global/theme/theme_data.dart';

Widget customContainer({
  required BuildContext context,
  required VoidCallback onTap,
  required double screenWidth,
  required String text,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          width: screenWidth * 0.98,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kDarkBlueColor, kDarkBlueColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: kWhiteColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
