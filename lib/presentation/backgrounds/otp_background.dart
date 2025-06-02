import 'package:flutter/material.dart';
import 'package:goods_admin/presentation/custom_widgets/App_Logo.dart';

class BuildBackground extends StatelessWidget {
  const BuildBackground({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight, // Set a specific height constraint
      child: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(
                      'assets/images/dreamy.jpg',
                    ))),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              //   child: Logo(height: 100, width: 150),
              // ),
              Stack(
                children: [
                  Transform(
                    alignment: Alignment.centerRight,
                    transform: Matrix4.rotationX(
                        3.14159), // Reflect the triangle vertically
                    child: const InvertedTriangleWidget(),
                  ),
                  logo(
                    height: 200,
                    width: 200,
                  )
                ],
              ),
              const TriangleWidget(),
            ],
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 190, 30, 19)
          .withOpacity(0.4) // Set the color of the triangle
      ..style = PaintingStyle.fill; // Set the style to fill the triangle

    final path = Path();
    path.moveTo(0, 0); // Top left corner
    path.lineTo(0, size.height); // Bottom left corner
    path.lineTo(size.width, size.height); // Bottom right corner
    path.close(); // Close the path to form a triangle

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class TriangleWidget extends StatelessWidget {
  const TriangleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width,
                300), // Set the size of the triangle
            painter: TrianglePainter(),
          ),
        ),
        const Positioned(
          top: 140,
          left: 50,
          child: Text(
            'مرحبا..',
            style: TextStyle(
                color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}

class InvertedTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 190, 30, 19)
          .withOpacity(0.4) // Set the color of the triangle
      ..style = PaintingStyle.fill; // Set the style to fill the triangle

    final path = Path();
    path.moveTo(0, 0); // Top left corner
    path.lineTo(0, size.height); // Bottom left corner
    path.lineTo(size.width / 1.5, size.height); // Bottom right corner
    path.close(); // Close the path to form a triangle

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class InvertedTriangleWidget extends StatelessWidget {
  const InvertedTriangleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width,
            200), // Set the size of the triangle
        painter: InvertedTrianglePainter(),
      ),
    );
  }
}
