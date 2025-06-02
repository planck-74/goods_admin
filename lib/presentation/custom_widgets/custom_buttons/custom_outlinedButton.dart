import 'package:flutter/material.dart';

Widget customOutlinedButton(
    {required double width,
    required double height,
    required BuildContext context,
    required Widget child,
    VoidCallback? onPressed}) {
  return SizedBox(
    width: width,
    height: 60,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        elevation: 5,
        foregroundColor: Theme.of(context).hoverColor,
        backgroundColor: const Color.fromARGB(255, 162, 79, 6).withOpacity(0.8),
        side: BorderSide(
          color: Theme.of(context).secondaryHeaderColor,
          width: width,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50.0),
        ),
        padding: EdgeInsets.zero,
      ),
      child: Center(child: child),
    ),
  );
}

Widget customOutlinedButton2(
    {required double width,
    required double height,
    required BuildContext context,
    required Widget child,
    VoidCallback? onPressed}) {
  return SizedBox(
    width: width,
    height: height,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).hoverColor,
        backgroundColor: Theme.of(context).secondaryHeaderColor,
        side: BorderSide(
          color: Theme.of(context).secondaryHeaderColor,
          width: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        padding: EdgeInsets.zero,
      ),
      child: Center(child: child),
    ),
  );
}
