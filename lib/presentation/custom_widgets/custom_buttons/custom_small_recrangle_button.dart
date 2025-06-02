import 'package:flutter/material.dart';

class SmallRectangleButton extends StatefulWidget {
  const SmallRectangleButton(
      {super.key,
      required this.onPressed1,
      required this.onPressed2,
      required this.onPressed3,
      required this.currentIndex});
  final VoidCallback onPressed1;
  final VoidCallback onPressed2;
  final VoidCallback onPressed3;

  final int currentIndex;
  @override
  State<SmallRectangleButton> createState() => _SmallRectangleButtonState();
}

class _SmallRectangleButtonState extends State<SmallRectangleButton> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        SizedBox(
          height: screenHeight * 0.8,
        ),
        SizedBox(
          height: 32,
          width: 85,
          child: ElevatedButton(
            onPressed: widget.currentIndex == 0
                ? widget.onPressed1
                : widget.onPressed2,
            style: ButtonStyle(
              shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              backgroundColor:
                  WidgetStatePropertyAll(Theme.of(context).hoverColor),
            ),
            child: Text(
              widget.currentIndex == 1 ? 'دخول' : 'التالي',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        widget.currentIndex > 0
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 32,
                    width: 85,
                    child: ElevatedButton(
                      onPressed: widget.onPressed3,
                      style: ButtonStyle(
                        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        backgroundColor: WidgetStatePropertyAll(
                            Theme.of(context).hoverColor),
                      ),
                      child: Text(
                        'السابق',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ),
                ],
              )
            : Container(),
      ],
    );
  }
}
