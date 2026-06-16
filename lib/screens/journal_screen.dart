import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'journal_history_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _journalController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedMood = 'Calm';
  String _supportType = 'Quran Reflection';
  String? _responseText;

  final List<Map<String, String>> _moods = [
    {'emoji': '😣', 'label': 'Stressed'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😊', 'label': 'Calm'},
    {'emoji': '🙂', 'label': 'Happy'},
  ];

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _generateSupportResponse() async {
  final journalText = _journalController.text.trim();

  if (journalText.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please write something first')),
    );
    return;
  }

  final userId = _supabase.auth.currentUser?.id;

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not logged in')),
    );
    return;
  }

  final responseText = _getResponseForMood(_selectedMood, _supportType);

  setState(() {
    _responseText = responseText;
  });

  try {
    await _supabase.from('journal_entries').insert({
      'user_id': userId,
      'mood': _selectedMood,
      'journal_text': journalText,
      'support_type': _supportType,
      'response_text': responseText,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Journal saved')),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Journal save failed: $e')),
    );
  }
}

void _startNewReflection() {
  setState(() {
    _journalController.clear();
    _responseText = null;
    _selectedMood = 'Calm';
    _supportType = 'Quran Reflection';
  });
}

  String _getResponseForMood(String mood, String type) {
    if (type == 'Quran Reflection') {
      switch (mood) {
        case 'Stressed':
          return '“Verily, with hardship comes ease.” — Quran 94:6\n\nTake a slow breath. This difficult moment is not permanent.';
        case 'Sad':
          return '“Do not lose hope, nor be sad.” — Quran 3:139\n\nYour feelings are valid. You are allowed to rest and heal.';
        case 'Happy':
          return '“If you are grateful, I will surely increase you.” — Quran 14:7\n\nHold onto this peaceful feeling and be thankful for today.';
        default:
          return '“Allah does not burden a soul beyond what it can bear.” — Quran 2:286\n\nYou are stronger than this moment.';
      }
    } else {
      switch (mood) {
        case 'Stressed':
          return 'Pause. Breathe. You do not have to solve everything at once. Take one small step at a time.';
        case 'Sad':
          return 'It is okay to feel low. Your emotions are not weakness; they are part of being human.';
        case 'Happy':
          return 'Celebrate this moment. Small moments of joy matter, and you deserve them.';
        default:
          return 'You are safe in this moment. Let your thoughts settle gently, one breath at a time.';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1FF),
      body: Stack(
        children: [
          _backgroundGlow(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(),
                  const SizedBox(height: 28),
                  _headline(),
                  const SizedBox(height: 28),
                  _moodSelector(),
                  const SizedBox(height: 24),
                  _journalBox(),
                  const SizedBox(height: 18),
                  _supportTypeSelector(),
                  const SizedBox(height: 18),
                  _saveButton(),
                  if (_responseText != null) ...[
  const SizedBox(height: 22),
  _responseCard(),
  const SizedBox(height: 14),
  _newReflectionButton(),
],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundGlow() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7F1FF),
            Color(0xFFEDE2FF),
            Color(0xFFFDF7FF),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -55,
            child: _glowCircle(const Color(0xFFB56CFF), 180),
          ),
          Positioned(
            top: 260,
            left: -90,
            child: _glowCircle(const Color(0xFFFF7EB6), 210),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _glowCircle(const Color(0xFF8D7CFF), 200),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.22),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        _glassCircleButton(
  icon: Icons.history_rounded,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JournalHistoryScreen(),
      ),
    );
  },
),
        const Spacer(),
        Text(
          'Reflection Journal',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D2638),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _glassCircleButton(
          icon: Icons.lock_outline_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _headline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How do you',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF292030),
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        Text(
          'feel today?',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFF9C6BFF),
            fontSize: 40,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Write your thoughts and receive a gentle reflection.',
          style: GoogleFonts.poppins(
            color: const Color(0xFF7E748D),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _moodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _moods.map((mood) {
        final isSelected = _selectedMood == mood['label'];

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedMood = mood['label']!;
            });
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isSelected ? 0.65 : 0.48),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFB68CFF)
                        : Colors.white.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF9C6BFF)
                          .withOpacity(isSelected ? 0.20 : 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    mood['emoji']!,
                    style: const TextStyle(fontSize: 27),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mood['label']!,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? const Color(0xFF8D5CFF)
                      : const Color(0xFF7E748D),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _journalBox() {
    return _glassContainer(
      child: SizedBox(
        height: 230,
        child: TextField(
          controller: _journalController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D2638),
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText:
                'Write your thoughts...\nThis is your private safe space.',
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFFB6ADBF),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _supportTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _choiceChip(
            title: 'Quran Reflection',
            icon: Icons.auto_stories_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _choiceChip(
            title: 'Motivational Quote',
            icon: Icons.favorite_border_rounded,
          ),
        ),
      ],
    );
  }

  Widget _choiceChip({
    required String title,
    required IconData icon,
  }) {
    final isSelected = _supportType == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _supportType = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFB16CFF),
                    Color(0xFF8C6BFF),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.45),
          border: Border.all(
            color: Colors.white.withOpacity(0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8C6BFF).withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF8D5CFF),
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : const Color(0xFF5F536B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButton() {
    return GestureDetector(
      onTap: _generateSupportResponse,
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFB16CFF),
              Color(0xFF7A5CFF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8C6BFF).withOpacity(0.34),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Save Reflection',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
Widget _newReflectionButton() {
  return GestureDetector(
    onTap: _startNewReflection,
    child: Container(
      height: 54,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.50),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.65),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C6BFF).withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.add_circle_outline_rounded,
            color: Color(0xFF8D5CFF),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'New Reflection',
            style: GoogleFonts.poppins(
              color: const Color(0xFF6F55D9),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _responseCard() {
    return _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_rounded, color: Color(0xFF8D5CFF)),
              const SizedBox(width: 8),
              Text(
                'Supportive Reflection',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2D2638),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _responseText!,
            style: GoogleFonts.poppins(
              color: const Color(0xFF5F536B),
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.45),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6A5B78),
              size: 19,
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.52),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C6BFF).withOpacity(0.10),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
