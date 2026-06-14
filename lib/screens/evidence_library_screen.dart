import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'evidence_detail_screen.dart';

class EvidenceLibraryScreen extends StatefulWidget {
  const EvidenceLibraryScreen({super.key});

  @override
  State<EvidenceLibraryScreen> createState() => _EvidenceLibraryScreenState();
}

class _EvidenceLibraryScreenState extends State<EvidenceLibraryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedFilter = 'All';

  Future<List<Map<String, dynamic>>> _loadEvidenceItems() async {
  final userId = _supabase.auth.currentUser?.id;

  if (userId == null) {
    throw Exception('User not logged in');
  }

  var query = _supabase
      .from('evidence_vault_items')
      .select()
      .eq('user_id', userId);

  if (_selectedFilter == 'Messages') {
    query = query.eq('evidence_type', 'message');
  }

  if (_selectedFilter == 'Photos') {
    query = query.eq('evidence_type', 'photo');
  }

  if (_selectedFilter == 'Videos') {
    query = query.eq('evidence_type', 'video');
  }

  final data = await query.order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(data);
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(context),
                  const SizedBox(height: 30),
                  _headline(),
                  const SizedBox(height: 24),
                  _filterRow(),
                  const SizedBox(height: 22),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadEvidenceItems(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _loadingCard();
                        }

                        if (snapshot.hasError) {
                          return _messageCard(
                            icon: Icons.error_outline_rounded,
                            title: 'Could not load evidence',
                            subtitle: 'Please check your connection and try again.',
                          );
                        }

                        final items = snapshot.data ?? [];

                        if (items.isEmpty) {
                          return _messageCard(
                            icon: Icons.lock_outline_rounded,
                            title: 'No evidence found',
                            subtitle:
                                'Saved messages, screenshots, and photos will appear here.',
                          );
                        }

                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _evidenceCard(items[index]);
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

  Widget _background() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF101018),
            Color(0xFF191426),
            Color(0xFF24162E),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -85,
            right: -75,
            child: _glowCircle(const Color(0xFF8B5CFF), 220),
          ),
          Positioned(
            top: 250,
            left: -110,
            child: _glowCircle(const Color(0xFFFF4D88), 230),
          ),
          Positioned(
            bottom: -95,
            right: -80,
            child: _glowCircle(const Color(0xFF5C7CFF), 230),
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

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        _glassCircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        Text(
          'Evidence Library',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _glassCircleButton(
          icon: Icons.lock_rounded,
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
          'Saved',
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        Text(
          'evidence',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFC7A6FF),
            fontSize: 42,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'View all preserved messages, screenshots, and photos with timestamps.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.62),
            fontSize: 13.5,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _filterRow() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _filterChip('All'),
        const SizedBox(width: 10),
        _filterChip('Messages'),
        const SizedBox(width: 10),
        _filterChip('Photos'),
        const SizedBox(width: 10),
        _filterChip('Videos'),
      ],
    ),
  );
}

  Widget _filterChip(String title) {
    final selected = _selectedFilter == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [
                    Color(0xFF8B5CFF),
                    Color(0xFFE05C9F),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.white.withOpacity(0.20)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

 Widget _evidenceCard(Map<String, dynamic> item) {
  final type = item['evidence_type']?.toString() ?? 'message';
  final title = item['title']?.toString() ?? 'Saved Evidence';
  final description = item['description']?.toString() ?? '';
  final text = item['encrypted_text']?.toString() ?? '';
  final createdAt = item['created_at_bd']?.toString() ?? '';

  final isMessage = type == 'message';
final isVideo = type == 'video';

final evidenceIcon = isMessage
    ? Icons.message_rounded
    : isVideo
        ? Icons.videocam_rounded
        : Icons.image_rounded;

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EvidenceDetailScreen(
            evidence: item,
          ),
        ),
      );
    },
    child: _glassContainer(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF9B6CFF),
                  Color(0xFFFF6F9F),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              evidenceIcon,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMessage
    ? (text.isEmpty ? description : text)
    : isVideo
        ? 'Video evidence file'
        : 'Screenshot / photo evidence',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.56),
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (createdAt.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: const Color(0xFFC7A6FF).withOpacity(0.85),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          createdAt.split('.').first,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFC7A6FF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withOpacity(0.42),
            size: 14,
          ),
        ],
      ),
    ),
  );
}

  Widget _loadingCard() {
    return _glassContainer(
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC7A6FF),
        ),
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return _glassContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.75),
            size: 34,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.52),
              fontSize: 12,
              height: 1.45,
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
              color: Colors.white.withOpacity(0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.16),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.88),
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
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 24,
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
