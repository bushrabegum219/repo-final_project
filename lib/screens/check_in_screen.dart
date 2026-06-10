import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  int selected = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              Row(
                children: [
                  _circleIcon(Icons.arrow_back_ios_new, () {
                    Navigator.pop(context);
                  }),
                  const Spacer(),
                  Text(
                    "AMAAN",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB68BFF),
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _circleIcon(Icons.more_vert, () {}),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                "Set Timer",
                style: GoogleFonts.poppins(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF151525),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                "Choose duration for your check-in",
                style: GoogleFonts.poppins(
                  color: Colors.black38,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 38),

              Container(
                height: 230,
                width: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEDE4FF),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Container(
                    height: 170,
                    width: 170,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB68BFF).withOpacity(0.18),
                          blurRadius: 35,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0E7FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.schedule,
                            color: Color(0xFFA64DFF),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "$selected",
                          style: GoogleFonts.poppins(
                            fontSize: 37,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF151525),
                          ),
                        ),
                        Text(
                          "MINUTES",
                          style: GoogleFonts.poppins(
                           color: Colors.black.withOpacity(0.30),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 38),

              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _timeOption(10, "10 min"),
                    _timeOption(30, "30 min"),
                    _timeOption(60, "1 hr"),
                  ],
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 56,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9457FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Start Timer",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 35,
        width: 35,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: Colors.black54),
      ),
    );
  }

  Widget _timeOption(int value, String text) {
    final isSelected = selected == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selected = value;
          });
        },
        child: Container(
          height: 47,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF1E8FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: isSelected ? const Color(0xFFA64DFF) : Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}