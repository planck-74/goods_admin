import 'package:flutter/material.dart';

Widget customTextField(
    {required double width,
    TextEditingController? controller,
    required String labelText,
    String? validationText,
    required context,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Center(
      child: Container(
        height: 60,
        width: width * 0.9,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8), // White background color
          borderRadius: BorderRadius.circular(3), // Rounded corners

          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5), // Shadow color
              spreadRadius: 2, // Spread radius
              blurRadius: 5, // Blur radius
              offset: const Offset(0, 3), // Shadow position (x, y)
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            focusedBorder: InputBorder.none,
            hintText: labelText, // Placeholder text inside the TextField
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 18),
            border: InputBorder.none, // No border
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 12.0), // Padding inside TextField
          ),
          validator: validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return validationText;
                }
                return null;
              },
        ),
      ),
    ),
  );
}
