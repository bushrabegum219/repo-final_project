import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyReminderScreen extends StatelessWidget {
  const DailyReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  _smallIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 34,
                    width: 34,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(
                          "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=300&auto=format&fit=crop",
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// TITLE
              Text(
                "Daily",
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF2D2438),
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "Protection",
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF9C8BC9),
                  fontSize: 28,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Your spiritual and physical safety shield.",
                style: GoogleFonts.poppins(
                  color: Colors.black45,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 22),

              /// DAILY DUA CARD
              _infoCard(
                iconBg: const Color(0xFFEDE7FF),
                iconColor: const Color(0xFFA58BEA),
                icon: Icons.auto_awesome_rounded,
                title: "DAILY DUA",
                trailing: const SizedBox(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "\"Hasbunallahu wa ni'mal wakeel\"",
                      style: GoogleFonts.playfairDisplay(
                        color: const Color(0xFF3A2F45),
                        fontSize: 17,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Sufficient for us is Allah, and [He is] the best Disposer of affairs.",
                      style: GoogleFonts.poppins(
                        color: Colors.black38,
                        fontSize: 10.8,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// SAFETY TIP CARD
              _infoCard(
                iconBg: const Color(0xFFFFF1D9),
                iconColor: const Color(0xFFFFB648),
                icon: Icons.lightbulb_rounded,
                title: "SAFETY TIP",
                trailing: Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: Colors.black26,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Stay Visible",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF30273B),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Keep your phone charged and visible when walking alone at night.",
                            style: GoogleFonts.poppins(
                              color: Colors.black38,
                              fontSize: 10.8,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3ECFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                        color: Color(0xFFA48ADF),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              /// STREAK HEADER
              Text(
                "Streak Level",
                style: GoogleFonts.playfairDisplay(
                  color: const Color(0xFF3A2F45),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              /// STREAK CARD
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _streakItem(
                      icon: Icons.home_rounded,
                      bg: const Color(0xFFF3F0F8),
                      selected: false,
                    ),
                    const Spacer(),
                    _streakItem(
                      icon: Icons.grid_view_rounded,
                      bg: const Color(0xFFF3F0F8),
                      selected: false,
                    ),
                    const Spacer(),
                    _centerStreakItem(),
                    const Spacer(),
                    _streakItem(
                      icon: Icons.favorite_rounded,
                      bg: const Color(0xFFF3F0F8),
                      selected: false,
                    ),
                    const Spacer(),
                    _streakItem(
                      icon: Icons.person_rounded,
                      bg: const Color(0xFFF3F0F8),
                      selected: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// OPTIONAL EXTRA SMALL CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECFF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCCFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF7E63D2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "You completed today’s protection reminder.",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF433453),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        height: 36,
        width: 36,
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

  Widget _smallIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.black45,
        ),
      ),
    );
  }

  Widget _infoCard({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required Widget trailing,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 26,
                width: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _streakItem({
    required IconData icon,
    required Color bg,
    required bool selected,
  }) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: selected ? const Color(0xFF8D73D8) : Colors.black38,
      ),
    );
  }

  Widget _centerStreakItem() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(
        Icons.shield_moon_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}