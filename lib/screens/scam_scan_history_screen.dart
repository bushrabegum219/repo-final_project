import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScamScanHistoryScreen extends StatefulWidget {
  const ScamScanHistoryScreen({super.key});

  @override
  State<ScamScanHistoryScreen> createState() => _ScamScanHistoryScreenState();
}

class _ScamScanHistoryScreenState extends State<ScamScanHistoryScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedFilter = 'All';

  static const Color _espresso = Color(0xFF160D0A);
  static const Color _caramel = Color(0xFFE1A46F);
  static const Color _cream = Color(0xFFFFEBDD);
  static const Color _softCream = Color(0xFFD8BFB0);

  Future<List<Map<String, dynamic>>> _loadScanHistory() async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User not logged in');
    }

    var query = _supabase
        .from('scam_detector_results')
        .select()
        .eq('user_id', userId);

    if (_selectedFilter != 'All') {
      query = query.eq('risk_level', _selectedFilter.toLowerCase());
    }

    final data = await query.order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Color _riskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'safe':
        return const Color(0xFF7ED9A6);
      case 'suspicious':
        return const Color(0xFFE6B15A);
      case 'dangerous':
        return const Color(0xFFE96E63);
      default:
        return _caramel;
    }
  }

  IconData _riskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'safe':
        return Icons.verified_user_rounded;
      case 'suspicious':
        return Icons.warning_amber_rounded;
      case 'dangerous':
        return Icons.gpp_bad_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  String _formatRisk(String risk) {
    if (risk.isEmpty) return 'Unknown';
    return risk[0].toUpperCase() + risk.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _espresso,
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
                  const SizedBox(height: 22),
                  _filterRow(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _loadScanHistory(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _loadingCard();
                        }

                        if (snapshot.hasError) {
                          return _messageCard(
                            icon: Icons.error_outline_rounded,
                            title: 'Could not load history',
                            subtitle:
                                'Please check your connection and try again.',
                          );
                        }

                        final scans = snapshot.data ?? [];

                        if (scans.isEmpty) {
                          return _messageCard(
                            icon: Icons.history_rounded,
                            title: 'No scans found',
                            subtitle:
                                'Your checked messages, links, and profiles will appear here.',
                          );
                        }

                        return ListView.separated(
                          itemCount: scans.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _scanCard(scans[index]);
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
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.35,
          colors: [
            Color(0xFF4B2C1F),
            Color(0xFF241410),
            Color(0xFF120907),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _glowCircle(const Color(0xFFB8794F), 240, 0.20),
          ),
          Positioned(
            top: 245,
            left: -120,
            child: _glowCircle(const Color(0xFFE1A46F), 260, 0.13),
          ),
          Positioned(
            bottom: -100,
            right: -90,
            child: _glowCircle(const Color(0xFF6D3827), 260, 0.26),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
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
          'Scan History',
          style: GoogleFonts.poppins(
            color: _cream,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        _glassCircleButton(
          icon: Icons.history_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _headline() {
    return _glassContainer(
      radius: 34,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.manage_search_rounded,
            color: _caramel,
            size: 34,
          ),
          const SizedBox(height: 18),
          Text(
            'Previous',
            style: GoogleFonts.playfairDisplay(
              color: _cream,
              fontSize: 42,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          Text(
            'safety scans',
            style: GoogleFonts.playfairDisplay(
              color: _caramel,
              fontSize: 40,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Review past scam and threat checks with their risk level, score, and timestamp.',
            style: GoogleFonts.poppins(
              color: _softCream.withOpacity(0.80),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('All'),
          const SizedBox(width: 10),
          _filterChip('Safe'),
          const SizedBox(width: 10),
          _filterChip('Suspicious'),
          const SizedBox(width: 10),
          _filterChip('Dangerous'),
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
                    Color(0xFF5A3427),
                    Color(0xFFB8794F),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? _caramel.withOpacity(0.35)
                : Colors.white.withOpacity(0.10),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: selected ? _cream : _softCream.withOpacity(0.78),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _scanCard(Map<String, dynamic> scan) {
    final risk = scan['risk_level']?.toString() ?? 'unknown';
    final scanType = scan['scan_type']?.toString() ?? 'scan';
    final content = scan['scanned_content']?.toString() ?? '';
    final score = scan['risk_score']?.toString() ?? '0';
    final createdAt = scan['created_at_bd']?.toString() ?? '';

    final color = _riskColor(risk);

    return GestureDetector(
      onTap: () => _showScanDetails(scan),
      child: _glassContainer(
        radius: 30,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(
                  color: color.withOpacity(0.35),
                ),
              ),
              child: Icon(
                _riskIcon(risk),
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatRisk(risk)} · $score%',
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scanType.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: _caramel.withOpacity(0.85),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: _softCream.withOpacity(0.72),
                      fontSize: 11.8,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (createdAt.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      createdAt.split('.').first,
                      style: GoogleFonts.poppins(
                        color: _softCream.withOpacity(0.50),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _softCream.withOpacity(0.40),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _showScanDetails(Map<String, dynamic> scan) {
    final risk = scan['risk_level']?.toString() ?? 'unknown';
    final content = scan['scanned_content']?.toString() ?? '';
    final reasons = List<String>.from(scan['reasons'] ?? []);
    final tips = List<String>.from(scan['safety_tips'] ?? []);
    final color = _riskColor(risk);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
              decoration: BoxDecoration(
                color: const Color(0xFF241410).withOpacity(0.96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(34),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Icon(
                          _riskIcon(risk),
                          color: color,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_formatRisk(risk)} Scan',
                          style: GoogleFonts.poppins(
                            color: _cream,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailBlock(
                      title: 'Scanned Content',
                      lines: [content],
                      dotColor: color,
                    ),
                    if (reasons.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _detailBlock(
                        title: 'Detection Reasons',
                        lines: reasons,
                        dotColor: color,
                      ),
                    ],
                    if (tips.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _detailBlock(
                        title: 'Safety Advice',
                        lines: tips,
                        dotColor: color,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailBlock({
    required String title,
    required List<String> lines,
    required Color dotColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: _cream,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      line,
                      style: GoogleFonts.poppins(
                        color: _softCream.withOpacity(0.78),
                        fontSize: 12.3,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _loadingCard() {
    return _glassContainer(
      child: const Center(
        child: CircularProgressIndicator(
          color: _caramel,
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
            color: _caramel,
            size: 36,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _cream,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _softCream.withOpacity(0.62),
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
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            child: Icon(
              icon,
              color: _cream.withOpacity(0.88),
              size: 19,
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
    double radius = 30,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.085),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.13),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 26,
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
