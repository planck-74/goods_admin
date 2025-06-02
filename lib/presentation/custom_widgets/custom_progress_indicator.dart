import 'package:flutter/material.dart';

Widget customCircularProgressIndicator({
  required context,
  double? height,
  double? width,
  Color? color,
  double? value,
}) {
  return SizedBox(
    height: height ?? 12,
    width: width ?? 12,
    child: Center(
      child: CircularProgressIndicator(
        value: value,
        color: color ?? Theme.of(context).dialogBackgroundColor,
      ),
    ),
  );
}
