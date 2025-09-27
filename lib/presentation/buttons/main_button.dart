import 'package:flutter/material.dart';
import 'package:goods_admin/presentation/custom_widgets/custom_container.dart';

Widget mainButton({
  required BuildContext context,
  required double screenWidth,
  required String text,
  required String routeName,
}) {
  return customContainer(
    context: context,
    onTap: () => Navigator.pushNamed(context, routeName),
    screenWidth: screenWidth,
    text: text,
  );
}
