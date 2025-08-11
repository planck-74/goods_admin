import 'package:flutter/material.dart';

const Color primaryColor = Color.fromARGB(255, 190, 30, 19);
const Color darkBlueColor = Color(0xFF012340);
const Color kLightBackgroundColor = Color.fromARGB(255, 242, 242, 242);
const Color whiteColor = Colors.white;
String storeId = 'cafb6e90-0ab1-11f0-b25a-8b76462b3bd5';
ThemeData getThemeData() {
  return ThemeData(
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: darkBlueColor),
    scaffoldBackgroundColor: kLightBackgroundColor,
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: darkBlueColor, selectionHandleColor: darkBlueColor),
    inputDecorationTheme: _inputDecorationTheme(),
    dropdownMenuTheme: _dropdownMenuTheme(),
    primarySwatch: Colors.red,
    primaryColor: primaryColor,
    secondaryHeaderColor: darkBlueColor,
    hoverColor: whiteColor,
    appBarTheme: const AppBarTheme(
      color: primaryColor,
      iconTheme: IconThemeData(color: whiteColor),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: primaryColor,
      height: 50,
    ),
    fontFamily: 'Cairo',
    textTheme: _textTheme(),
    dialogTheme: DialogThemeData(backgroundColor: whiteColor),
  );
}

InputDecorationTheme _inputDecorationTheme() {
  return const InputDecorationTheme(
    labelStyle: TextStyle(color: darkBlueColor, fontSize: 16),
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: Color.fromARGB(255, 0, 29, 54),
        width: 2.0,
      ),
    ),
  );
}

DropdownMenuThemeData _dropdownMenuTheme() {
  return const DropdownMenuThemeData(
    textStyle: TextStyle(
      color: darkBlueColor,
      fontSize: 18,
      fontFamily: 'Cairo',
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: darkBlueColor, fontSize: 12),
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: darkBlueColor,
          width: 2.0,
        ),
      ),
    ),
  );
}

TextTheme _textTheme() {
  return TextTheme(
    headlineLarge: _textStyle(
        color: darkBlueColor, fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: _textStyle(color: darkBlueColor, fontSize: 14),
    headlineSmall: _textStyle(color: darkBlueColor, fontSize: 12),
    bodyLarge: _textStyle(
        color: darkBlueColor, fontSize: 24, fontWeight: FontWeight.bold),
    bodyMedium: _textStyle(
        color: darkBlueColor, fontSize: 18, fontWeight: FontWeight.bold),
    bodySmall: _textStyle(
        color: darkBlueColor, fontSize: 12, fontWeight: FontWeight.bold),
  );
}

TextStyle _textStyle(
    {required Color color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}
