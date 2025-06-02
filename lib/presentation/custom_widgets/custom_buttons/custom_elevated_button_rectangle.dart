import 'package:flutter/material.dart';

Widget customElevatedButtonRectangle(
    {required double screenWidth,
    required BuildContext context,
    required Widget child}) {
  return SizedBox(
    height: 50,
    width: screenWidth * 0.9,
    child: ElevatedButton(
        onPressed: () {},
        style: ButtonStyle(
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.0),
                    side: BorderSide(color: Theme.of(context).primaryColor))),
            backgroundColor:
                WidgetStatePropertyAll(Theme.of(context).primaryColor)),
        child: child),
  );
}
