import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SimpleMapPainter(),
              ),
            ),

            Positioned.fill(
              child: Container(
                color: const Color(0xFFFFF7EF).withOpacity(0.35),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.94),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _topCircleButton(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "Your Location",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3A3348),
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        _topCircleButton(
                          icon: Icons.search_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E9FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 6,
                            width: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF9B7BE8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            "Location Active",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF9B7BE8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 178,
                      width: 178,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB99CF0).withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      height: 4,
                      width: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9B7BE8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B7BE8),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9B7BE8)
                                    .withOpacity(0.32),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B7BE8).withOpacity(0.35),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 5,
                      width: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6E0EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFF0ECF7),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.035),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0E9FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.location_pin,
                              color: Color(0xFF9B7BE8),
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "CURRENT ADDRESS",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFFB2A9C3),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "123 Safe Haven Blvd",
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF342D42),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Metro District, City",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black38,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Current location shared"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        height: 54,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFA685F0),
                              Color(0xFF8F6AE8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9B7BE8).withOpacity(0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Share Current Location",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F6FB),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Color(0xFF6C627C),
          size: 16,
        ),
      ),
    );
  }
}

class _SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = const Color(0xFFF4E8DA)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final thinRoadPaint = Paint()
      ..color = Colors.white.withOpacity(0.45)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(size.width * 0.60, 0)
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.18,
        size.width * 0.46,
        size.height * 0.30,
        size.width * 0.50,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.54,
        size.height * 0.65,
        size.width * 0.43,
        size.height * 0.78,
        size.width * 0.47,
        size.height,
      );

    final path2 = Path()
      ..moveTo(0, size.height * 0.55)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.48,
        size.width * 0.40,
        size.height * 0.57,
        size.width * 0.62,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.45,
        size.width * 0.88,
        size.height * 0.42,
        size.width,
        size.height * 0.36,
      );

    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path2, roadPaint);

    for (double i = 0.10; i < 0.95; i += 0.14) {
      final p = Path()
        ..moveTo(size.width * i, 0)
        ..cubicTo(
          size.width * (i + 0.05),
          size.height * 0.22,
          size.width * (i - 0.04),
          size.height * 0.42,
          size.width * (i + 0.02),
          size.height * 0.70,
        )
        ..cubicTo(
          size.width * (i + 0.04),
          size.height * 0.82,
          size.width * (i - 0.03),
          size.height * 0.90,
          size.width * i,
          size.height,
        );

      canvas.drawPath(p, thinRoadPaint);
    }

    for (double j = 0.18; j < 0.95; j += 0.16) {
      final p = Path()
        ..moveTo(0, size.height * j)
        ..cubicTo(
          size.width * 0.22,
          size.height * (j - 0.03),
          size.width * 0.45,
          size.height * (j + 0.04),
          size.width * 0.66,
          size.height * j,
        )
        ..cubicTo(
          size.width * 0.78,
          size.height * (j - 0.02),
          size.width * 0.90,
          size.height * (j + 0.04),
          size.width,
          size.height * j,
        );

      canvas.drawPath(p, thinRoadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
