import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PanicScreen extends StatelessWidget {
  const PanicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      /// TOP BAR
                      Row(
                        children: [
                          _circleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Text(
                                "•",
                                style: TextStyle(
                                  color: Color(0xFFFF4D5E),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Emergency Mode",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFFF4D5E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          _circleButton(
                            icon: Icons.more_vert_rounded,
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      /// ALERT CIRCLE
                      Center(
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF4D5E).withOpacity(0.06),
                          ),
                          child: Center(
                            child: Container(
                              width: 162,
                              height: 162,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFFF4D5E).withOpacity(0.10),
                              ),
                              child: Center(
                                child: Container(
                                  width: 114,
                                  height: 114,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFFF3F52),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF3F52).withOpacity(0.28),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Alert Sent!",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        "HELP IS ON THE WAY",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// STATUS CARD 1
                      _statusCard(
                        iconBg: const Color(0xFFE9FFF1),
                        iconColor: const Color(0xFF36C980),
                        icon: Icons.location_on_rounded,
                        title: "Location Shared",
                        subtitle: "Live tracking active",
                        trailing: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAFBF0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Color(0xFF5FD38E),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// STATUS CARD 2
                      _statusCard(
                        iconBg: const Color(0xFFFFF0F0),
                        iconColor: const Color(0xFFFF8A8A),
                        icon: Icons.mic_rounded,
                        title: "Recording Started",
                        subtitle: "Audio & video capturing",
                        trailing: Text(
                          "00:42",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFFF5B6B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// CONTACT HEADER
                      Row(
                        children: [
                          Text(
                            "NOTIFIED CONTACTS",
                            style: GoogleFonts.poppins(
                              color: Colors.black38,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "3 Notified",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFF5B6B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// CONTACTS
                      Row(
                        children: [
                          _contactItem(
                            name: "Mom",
                            letter: "M",
                            bgColor: const Color(0xFFDFF4E5),
                            textColor: const Color(0xFF35A76E),
                          ),
                          const SizedBox(width: 18),
                          _contactItem(
                            name: "Dad",
                            letter: "D",
                            bgColor: const Color(0xFF2C2C2C),
                            textColor: Colors.white,
                          ),
                          const SizedBox(width: 18),
                          _contactItem(
                            name: "Sarah",
                            letter: "S",
                            bgColor: const Color(0xFFE5E5E5),
                            textColor: const Color(0xFF8A8A8A),
                          ),
                        ],
                      ),

                      const Spacer(),

                      const SizedBox(height: 24),

                      /// CALL POLICE BUTTON
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF434F),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF434F).withOpacity(0.26),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  "Call Police (911)",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Cancel Emergency Mode",
                        style: GoogleFonts.poppins(
                          color: Colors.black45,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _statusCard({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.028),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2B2733),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.black38,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _contactItem({
    required String name,
    required String letter,
    required Color bgColor,
    required Color textColor,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              letter,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.poppins(
            color: const Color(0xFF333333),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}