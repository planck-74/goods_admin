import 'package:flutter/material.dart';

// Define color constants for reusability
const Color kPrimaryColor = Color.fromARGB(255, 190, 30, 19);
const Color kDarkBlueColor = Color(0xFF012340);
const Color kLightBackgroundColor = Color.fromARGB(255, 242, 242, 242);
const Color kWhiteColor = Colors.white;

ThemeData getThemeData() {
  return ThemeData(
    // progressIndicator
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: kWhiteColor),
    // Background colors
    dialogBackgroundColor: kDarkBlueColor,
    scaffoldBackgroundColor: kLightBackgroundColor,

    // Text selection theme
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: kDarkBlueColor, selectionHandleColor: kDarkBlueColor),

    // Input decoration theme (for TextField label style)
    inputDecorationTheme: _inputDecorationTheme(),

    // DropdownButton global style
    dropdownMenuTheme: _dropdownMenuTheme(),

    // Primary color scheme
    primarySwatch: Colors.red,
    primaryColor: kPrimaryColor,
    secondaryHeaderColor: kDarkBlueColor,

    // Hover color
    hoverColor: kWhiteColor,

    // AppBar theme
    appBarTheme: const AppBarTheme(
      color: kPrimaryColor,
      iconTheme: IconThemeData(color: kWhiteColor),
    ),

    // Button theme (removed unused property `elevatedButtonTheme`)
    buttonTheme: const ButtonThemeData(
      buttonColor: kPrimaryColor,
      height: 50,
    ),

    // Global text theme
    fontFamily: 'Cairo',
    textTheme: _textTheme(),
  );
}

InputDecorationTheme _inputDecorationTheme() {
  return const InputDecorationTheme(
    labelStyle: TextStyle(color: kDarkBlueColor, fontSize: 16),
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
      color: kDarkBlueColor,
      fontSize: 18,
      fontFamily: 'Cairo',
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: kDarkBlueColor, fontSize: 12),
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: kDarkBlueColor,
          width: 2.0,
        ),
      ),
    ),
  );
}

TextTheme _textTheme() {
  return TextTheme(
    headlineLarge: _textStyle(
        color: kDarkBlueColor, fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: _textStyle(color: kDarkBlueColor, fontSize: 14),
    headlineSmall: _textStyle(color: kDarkBlueColor, fontSize: 12),
    bodyLarge: _textStyle(
        color: kDarkBlueColor, fontSize: 24, fontWeight: FontWeight.bold),
    bodyMedium: _textStyle(
        color: kDarkBlueColor, fontSize: 18, fontWeight: FontWeight.bold),
    bodySmall: _textStyle(
        color: kDarkBlueColor, fontSize: 12, fontWeight: FontWeight.bold),
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
