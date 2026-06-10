import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  String selectedMood = "Calm";

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  void _selectMood(String mood) {
    setState(() {
      selectedMood = mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TOP BAR
                    Row(
                      children: [
                        Container(
                          height: 38,
                          width: 38,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEADFFB),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF8F67E8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "GOOD MORNING",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFFB1A8C3),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                "Sarah Jenkins",
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF2F2940),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _topIcon(Icons.calendar_today_outlined),
                        const SizedBox(width: 8),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _topIcon(Icons.notifications_none_rounded),
                            Positioned(
                              right: 2,
                              top: 3,
                              child: Container(
                                height: 7,
                                width: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7993),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    /// TITLE
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "How do you\n",
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFF2B2438),
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          TextSpan(
                            text: "feel today?",
                            style: GoogleFonts.playfairDisplay(
                              color: const Color(0xFF9A70EE),
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              fontStyle: FontStyle.italic,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Take a moment to reflect on your emotions.",
                      style: GoogleFonts.poppins(
                        color: Colors.black45,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// MOOD ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _moodItem("😣", "Stressed", selectedMood == "Stressed"),
                        _moodItem("😔", "Sad", selectedMood == "Sad"),
                        _moodItem("😊", "Calm", selectedMood == "Calm"),
                        _moodItem("🙂", "Happy", selectedMood == "Happy"),
                      ],
                    ),

                    const SizedBox(height: 22),

                    /// JOURNAL CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.035),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 112,
                            child: TextField(
                              controller: _journalController,
                              maxLines: null,
                              expands: true,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF322B40),
                                fontSize: 12.2,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    "Write your thoughts... Let it all out.\nThis is your safe space.",
                                hintStyle: GoogleFonts.poppins(
                                  color: const Color(0xFFC0B8CF),
                                  fontSize: 11.7,
                                  height: 1.55,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 30,
                                width: 30,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF8F5FB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.mic_rounded,
                                  color: Colors.black87,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9A63F0),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF9A63F0)
                                          .withOpacity(0.28),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// LOWER CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 26,
                            width: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFCDB7FA),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: SizedBox(
                                height: 12,
                                width: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFB288F4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            "Your reflections help you understand\npatterns in your emotions.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.black45,
                              fontSize: 10.8,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// BOTTOM NAV BAR
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.97),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(26),
                  topRight: Radius.circular(26),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navIcon(Icons.home_filled, false),
                  _navIcon(Icons.article_outlined, false),
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2E9FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE1D0FF),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFAF8AF4),
                      size: 20,
                    ),
                  ),
                  _navIcon(Icons.favorite_border_rounded, false),
                  _navIcon(Icons.person_outline_rounded, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topIcon(IconData icon) {
    return Container(
      height: 34,
      width: 34,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: const Color(0xFF6F647E),
        size: 16,
      ),
    );
  }

  Widget _moodItem(String emoji, String label, bool selected) {
    return GestureDetector(
      onTap: () => _selectMood(label),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFF1E8FF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFFD8C0FF)
                    : const Color(0xFFF0EBF7),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? const Color(0xFF9A70EE) : Colors.black54,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, bool selected) {
    return Icon(
      icon,
      color: selected ? const Color(0xFF9A70EE) : Colors.black54,
      size: 20,
    );
  }
}