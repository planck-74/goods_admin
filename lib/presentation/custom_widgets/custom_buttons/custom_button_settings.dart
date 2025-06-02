import 'package:flutter/material.dart';

Widget customButtonMoreScreen(
    {required BuildContext context,
    required String text,
    required IconData icon,
    required Color color,
    GestureTapCallback? onTap}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
              ),
              const SizedBox(
                width: 24,
              ),
              Text(
                text,
                style: TextStyle(color: color, fontSize: 12),
              )
            ],
          ),
          Divider(
            indent: 30,
            endIndent: 30,
            color: color,
          )
        ],
      ),
    ),
  );
}

Widget customButtonMoreScreenWithImage(
    {required BuildContext context,
    required String text,
    required String icon,
    required Color color}) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      children: [
        Row(
          children: [
            ImageIcon(
              AssetImage(icon),
              color: color,
            ),
            const SizedBox(
              width: 24,
            ),
            Text(
              text,
              style: TextStyle(color: color, fontSize: 12),
            )
          ],
        ),
        Divider(
          indent: 30,
          endIndent: 30,
          color: color,
        )
      ],
    ),
  );
}
