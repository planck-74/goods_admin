import 'package:flutter/material.dart';

Widget logo({required double height, required double width}) {
  return Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      height: height,
      width: width,
      child: Image.asset('assets/images/app_logo_black.png'),
    ),
  );
}
