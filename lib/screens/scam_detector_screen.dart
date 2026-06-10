import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScamDetectorScreen extends StatefulWidget {
  const ScamDetectorScreen({super.key});

  @override
  State<ScamDetectorScreen> createState() => _ScamDetectorScreenState();
}

class _ScamDetectorScreenState extends State<ScamDetectorScreen> {
  final TextEditingController _controller = TextEditingController();

  void _analyzeContent() {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please paste a message or link first"),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Content analyzed"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TOP BAR
              Row(
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    "SAFETY TOOLS",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB2A8C8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const Spacer(),
                  _circleButton(
                    icon: Icons.info_outline_rounded,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// TITLE
              Text(
                "Check Safety",
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF322B3D),
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Paste a message, link, or contact detail below to verify\nits safety and authenticity.",
                style: GoogleFonts.poppins(
                  color: Colors.black45,
                  fontSize: 11,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 18),

              /// INPUT CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      height: 86,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F5FB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextField(
                        controller: _controller,
                        maxLines: null,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF332C3F),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: "Paste message or link here...",
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.black26,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _miniActionButton(
                          icon: Icons.paste_rounded,
                          onTap: () {},
                        ),
                        const SizedBox(width: 8),
                        _miniActionButton(
                          icon: Icons.link_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              /// ANALYZE BUTTON
              GestureDetector(
                onTap: _analyzeContent,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF9D71E8),
                        Color(0xFF8F63DD),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8F63DD).withOpacity(0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Analyze Content",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// RECENT RESULTS HEADER
              Row(
                children: [
                  Text(
                    "RECENT RESULTS",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFB1A7C5),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// SAFE LINK CARD
              _resultCard(
                iconBg: const Color(0xFFE9FBEF),
                iconColor: const Color(0xFF54C778),
                icon: Icons.check_rounded,
                title: "Safe Link",
                subtitle: "uber.com/driver-trip-12345",
                badgeText: "Verified Domain",
                badgeColor: const Color(0xFFE6F8EC),
                badgeTextColor: const Color(0xFF49B96D),
                time: "Just now",
                titleColor: const Color(0xFF48B96A),
              ),

              const SizedBox(height: 12),

              /// SUSPICIOUS MESSAGE CARD
              _resultCard(
                iconBg: const Color(0xFFFFEEEE),
                iconColor: const Color(0xFFFF6B6B),
                icon: Icons.warning_rounded,
                title: "Suspicious Message",
                subtitle: "\"Win a free iPhone click here...\"",
                badgeText: "Phishing Pattern",
                badgeColor: const Color(0xFFFFF0F0),
                badgeTextColor: const Color(0xFFFF6D6D),
                time: "2 mins ago",
                titleColor: const Color(0xFFE86A6A),
              ),

              const SizedBox(height: 18),

              /// DAILY TIP
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E9FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.lightbulb_rounded,
                        size: 16,
                        color: Color(0xFF9B7AE6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 10.6,
                            height: 1.45,
                          ),
                          children: const [
                            TextSpan(
                              text: "Daily Safety Tip: ",
                              style: TextStyle(
                                color: Color(0xFF6C5E88),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text:
                                  "Never share OTPs or click links without first verifying the source.",
                              style: TextStyle(
                                color: Colors.black45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
            ],
          ),
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
        height: 34,
        width: 34,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.black45,
          size: 17,
        ),
      ),
    );
  }

  Widget _miniActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 26,
        width: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFF0E9FF),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          icon,
          size: 14,
          color: const Color(0xFF9A79E5),
        ),
      ),
    );
  }

  Widget _resultCard({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String time,
    required Color titleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      time,
                      style: GoogleFonts.poppins(
                        color: Colors.black26,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.black45,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.poppins(
                      color: badgeTextColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}