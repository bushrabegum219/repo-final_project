import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrustedCircleScreen extends StatelessWidget {
  const TrustedCircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F1FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  _roundButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    "Trusted Contacts",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1A2E),
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    children: [
                      _roundButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () {},
                      ),
                      Positioned(
                        right: 9,
                        top: 8,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF445C),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEF1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: Color(0xFFFF445C),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Emergency SOS",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1A2E),
                            ),
                          ),
                          Text(
                            "Alert all trusted contacts\ninstantly",
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              height: 1.2,
                              color: Colors.black38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 38,
                      width: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF445C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flash_on_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.black26,
                      size: 20,
                    ),
                    hintText: "Search contacts...",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.black26,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 14),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _filterChip("All", true),
                  _filterChip("Family", false),
                  _filterChip("Friends", false),
                  _filterChip("Work", false),
                ],
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8D3BFF),
                      Color(0xFFC849F8),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    _avatar(
                      text: "M",
                      bg: const Color(0xFFE8D8FF),
                      textColor: const Color(0xFF8D3BFF),
                      size: 46,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Mom",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                height: 6,
                                width: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF68F59D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Family • Primary",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 11),
                          Text(
                            "Last active",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 9.5,
                            ),
                          ),
                          Text(
                            "10 mins ago",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _smallPurpleIcon(Icons.add_rounded),
                    const SizedBox(width: 8),
                    _whiteActionIcon(Icons.call_rounded),
                    const SizedBox(width: 8),
                    _whiteActionIcon(Icons.location_on_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 13),

              _contactTile(
                name: "Sarah Jenkins",
                relation: "Sister",
                letter: "S",
                bg: const Color(0xFFEAF7EF),
                textColor: const Color(0xFF4E9F6E),
              ),
              _contactTile(
                name: "Emma Wilson",
                relation: "Best Friend",
                letter: "E",
                bg: const Color(0xFFEAF1FF),
                textColor: const Color(0xFF5D7FEA),
              ),
              _contactTile(
                name: "Dad",
                relation: "Family",
                letter: "D",
                bg: const Color(0xFFEEDCFF),
                textColor: const Color(0xFFB55CFF),
              ),

              const SizedBox(height: 16),

              Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFAB42F5),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Center(
                  child: Text(
                    "+ Add New Contact",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black54, size: 18),
      ),
    );
  }

  Widget _filterChip(String text, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: selected ? Colors.white : Colors.black54,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _avatar({
    required String text,
    required Color bg,
    required Color textColor,
    double size = 44,
  }) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _smallPurpleIcon(IconData icon) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white70, size: 16),
    );
  }

  Widget _whiteActionIcon(IconData icon) {
    return Container(
      height: 32,
      width: 32,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Color(0xFF9D3EFF), size: 17),
    );
  }

  Widget _contactTile({
    required String name,
    required String relation,
    required String letter,
    required Color bg,
    required Color textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          _avatar(text: letter, bg: bg, textColor: textColor, size: 43),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1F1A2E),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  relation,
                  style: GoogleFonts.poppins(
                    color: Colors.black38,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 25,
            width: 25,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F0F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Colors.black26,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}