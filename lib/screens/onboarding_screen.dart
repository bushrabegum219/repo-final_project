import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final PageController _controller = PageController();

  final List<Map<String, String>> data = [
    {
      "title": "Real-Time Protection",
      "desc": "Stay aware of your surroundings with smart alerts."
    },
    {
      "title": "Instant SOS",
      "desc": "Send emergency alerts with one tap."
    },
    {
      "title": "AI Safety Layer",
      "desc": "Intelligent monitoring for your daily life."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: Column(
        children: [

          /// 🔄 PAGES
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: data.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      /// 🔷 ICON (placeholder for now)
                      Icon(
                        Icons.shield_rounded,
                        size: 100,
                        color: Colors.deepPurple.shade300,
                      ),

                      const SizedBox(height: 40),

                      Text(
                        data[index]["title"]!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        data[index]["desc"]!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          /// 🔘 BUTTON
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // or go to HomeScreen later
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E7CFF),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                "Continue",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
