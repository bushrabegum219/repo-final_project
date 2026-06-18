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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in')));
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Journal saved')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Journal save failed: $e')));
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
    final Map<String, Map<String, List<String>>> responses = {
      'Quran Reflection': {
        'Stressed': [
          'Quran 94:5–6 reminds us that ease comes with hardship.\n\nTake one slow breath. This pressure is heavy, but it is not permanent.',
          'Quran 2:286 reminds us that Allah does not burden a soul beyond what it can bear.\n\nYou do not need to solve everything today. Begin with one small step.',
          'Quran 13:28 reminds us that hearts find peace through the remembrance of Allah.\n\nPause for a moment. Let your heart return to calm slowly.',
          'Quran 65:3 reminds us that Allah provides from ways we may not expect.\n\nEven when the path feels unclear, you are not without support.',
          'Quran 3:173 reminds believers to place trust in Allah.\n\nThis stressful moment can pass. Hold yourself gently and keep going.',
        ],
        'Sad': [
          'Quran 3:139 reminds us not to lose heart or fall into despair.\n\nYour sadness is real, but it does not define your future.',
          'Quran 93:3 reminds us that Allah has not abandoned us.\n\nEven when your heart feels quiet and tired, you are still cared for.',
          'Quran 12:87 reminds us not to despair of Allah’s mercy.\n\nLet this be a soft reminder that healing can come slowly, one day at a time.',
          'Quran 21:83 shows the patience of Prophet Ayyub during hardship.\n\nYour pain matters. You can rest without giving up.',
          'Quran 2:153 reminds us to seek help through patience and prayer.\n\nToday may feel heavy, but you do not have to carry it alone.',
        ],
        'Calm': [
          'Quran 13:28 reminds us that remembrance brings peace to the heart.\n\nStay with this calm feeling. Let it settle gently inside you.',
          'Quran 2:286 reminds us that Allah knows our capacity.\n\nThis peaceful moment is a chance to breathe, reflect, and reset.',
          'Quran 16:18 reminds us that Allah’s blessings are beyond counting.\n\nNotice one small blessing around you and hold gratitude for it.',
          'Quran 20:46 reminds us that Allah is near and aware.\n\nYou are safe in this moment. Let your thoughts become lighter.',
          'Quran 94:5–6 reminds us that ease follows hardship.\n\nThis calm may be the ease your heart needed today.',
        ],
        'Happy': [
          'Quran 14:7 reminds us that gratitude increases blessings.\n\nEnjoy this happiness and let thankfulness make it even brighter.',
          'Quran 55 repeatedly asks us to notice the blessings around us.\n\nLet today’s joy remind you of the good that still exists.',
          'Quran 2:152 reminds us to remember Allah and be grateful.\n\nThis happy feeling is worth protecting and appreciating.',
          'Quran 31:12 reminds us that gratitude benefits the grateful heart.\n\nSmile at this moment. You deserve to feel light.',
          'Quran 16:18 reminds us that blessings cannot truly be counted.\n\nLet this joyful moment become a memory you can return to later.',
        ],
      },
      'Motivational Quote': {
        'Stressed': [
          'Pause. Breathe. You do not have to fix everything at once. One small step is enough for now.',
          'Stress can make everything feel urgent. Slow down and choose the next right action.',
          'You are allowed to rest before continuing. Rest is not failure; it is preparation.',
          'This moment feels intense, but you have handled difficult days before.',
          'Focus on what you can control right now. Let the rest wait for a little while.',
        ],
        'Sad': [
          'It is okay to feel low. Your emotions are not weakness; they are part of being human.',
          'Be gentle with yourself today. Healing does not need to be rushed.',
          'Sad days do not erase your strength. They only ask you to move softly.',
          'You are not behind. You are simply going through something that needs care.',
          'Let yourself feel, but do not let this feeling convince you that hope is gone.',
        ],
        'Calm': [
          'You are safe in this moment. Let your thoughts settle gently, one breath at a time.',
          'Calm is a quiet kind of strength. Stay present and protect this peace.',
          'This is a good moment to listen to yourself without pressure.',
          'Let your mind slow down. You do not always need to be rushing.',
          'Peace grows when you give yourself permission to pause.',
        ],
        'Happy': [
          'Celebrate this moment. Small moments of joy matter, and you deserve them.',
          'Let yourself enjoy the good without feeling guilty for it.',
          'Happiness is worth noticing. Save this feeling in your heart.',
          'Today gave you something bright. Let it remind you that good days can return.',
          'Share your light with yourself first. You deserve this joy.',
        ],
      },
    };

    final moodResponses =
        responses[type]?[mood] ?? responses[type]?['Calm'] ?? const [];

    if (moodResponses.isEmpty) {
      return 'Take a slow breath. You are safe in this moment, and your feelings matter.';
    }

    final seed =
        DateTime.now().microsecondsSinceEpoch +
        _journalController.text.hashCode +
        mood.hashCode +
        type.hashCode;

    return moodResponses[seed.abs() % moodResponses.length];
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
          colors: [Color(0xFFF7F1FF), Color(0xFFEDE2FF), Color(0xFFFDF7FF)],
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
        _glassCircleButton(icon: Icons.lock_outline_rounded, onTap: () {}),
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
                      color: const Color(
                        0xFF9C6BFF,
                      ).withOpacity(isSelected ? 0.20 : 0.08),
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

  Widget _choiceChip({required String title, required IconData icon}) {
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
                  colors: [Color(0xFFB16CFF), Color(0xFF8C6BFF)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.45),
          border: Border.all(color: Colors.white.withOpacity(0.55)),
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
            colors: [Color(0xFFB16CFF), Color(0xFF7A5CFF)],
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
          border: Border.all(color: Colors.white.withOpacity(0.65)),
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
            child: Icon(icon, color: const Color(0xFF6A5B78), size: 19),
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({required Widget child}) {
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
            border: Border.all(color: Colors.white.withOpacity(0.55)),
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
