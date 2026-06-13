import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class JournalHistoryScreen extends StatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  State<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _loadJournalEntries() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final data = await _supabase
        .from('journal_entries')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F1FF),
      body: Stack(
        children: [
          _backgroundGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(),
                  const SizedBox(height: 26),
                  Text(
                    'Saved Reflections',
                    style: GoogleFonts.playfairDisplay(
                      color: const Color(0xFF292030),
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your private journal history and supportive responses.',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF7E748D),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadJournalEntries(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF9C6BFF),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Could not load journal entries',
                              style: GoogleFonts.poppins(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }

                        final entries = snapshot.data ?? [];

                        if (entries.isEmpty) {
                          return _emptyState();
                        }

                        return ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _journalCard(entries[index]);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: _glassCircle(
            icon: Icons.arrow_back_ios_new_rounded,
          ),
        ),
        const Spacer(),
        Text(
          'Journal Library',
          style: GoogleFonts.poppins(
            color: const Color(0xFF2D2638),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _glassCircle(
          icon: Icons.lock_outline_rounded,
        ),
      ],
    );
  }

  Widget _journalCard(Map<String, dynamic> entry) {
    final mood = entry['mood']?.toString() ?? '';
    final supportType = entry['support_type']?.toString() ?? '';
    final journalText = entry['journal_text']?.toString() ?? '';
    final responseText = entry['response_text']?.toString() ?? '';
    final createdAt = entry['created_at_bd']?.toString() ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.60),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C6BFF).withOpacity(0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _moodBadge(mood),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      supportType,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF8D5CFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                journalText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF2D2638),
                  fontSize: 13.5,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EAFF).withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  responseText,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF5F536B),
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (createdAt.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  createdAt.split('.').first,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9B92A8),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _moodBadge(String mood) {
    String emoji = '😊';

    if (mood == 'Stressed') emoji = '😣';
    if (mood == 'Sad') emoji = '😔';
    if (mood == 'Happy') emoji = '🙂';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$emoji $mood',
        style: GoogleFonts.poppins(
          color: const Color(0xFF5F536B),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Text(
        'No saved reflections yet',
        style: GoogleFonts.poppins(
          color: const Color(0xFF7E748D),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _glassCircle({
    required IconData icon,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
    );
  }
}
