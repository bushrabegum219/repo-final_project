import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scam_scan_history_screen.dart';

enum ScamRiskLevel {
  safe,
  suspicious,
  dangerous,
}

class ScamDetectorScreen extends StatefulWidget {
  const ScamDetectorScreen({super.key});

  @override
  State<ScamDetectorScreen> createState() => _ScamDetectorScreenState();
}

class _ScamDetectorScreenState extends State<ScamDetectorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedType = 'Message';
  ScamRiskLevel? _riskLevel;
  int _riskScore = 0;
  List<String> _reasons = [];
  List<String> _safetyTips = [];

  static const Color _espresso = Color(0xFF160D0A);
  static const Color _mocha = Color(0xFF241410);
  static const Color _cocoa = Color(0xFF332019);
  static const Color _bronze = Color(0xFFB8794F);
  static const Color _caramel = Color(0xFFE1A46F);
  static const Color _cream = Color(0xFFFFEBDD);
  static const Color _softCream = Color(0xFFD8BFB0);

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
  String _riskLevelToText(ScamRiskLevel level) {
  switch (level) {
    case ScamRiskLevel.safe:
      return 'safe';
    case ScamRiskLevel.suspicious:
      return 'suspicious';
    case ScamRiskLevel.dangerous:
      return 'dangerous';
  }
}

Future<void> _saveScanResult({
  required String scannedContent,
  required ScamRiskLevel level,
  required int score,
  required List<String> reasons,
  required List<String> safetyTips,
}) async {
  final userId = _supabase.auth.currentUser?.id;

  if (userId == null) {
    return;
  }

  try {
    await _supabase.from('scam_detector_results').insert({
      'user_id': userId,
      'scan_type': _selectedType.toLowerCase(),
      'scanned_content': scannedContent,
      'risk_level': _riskLevelToText(level),
      'risk_score': score,
      'reasons': reasons,
      'safety_tips': safetyTips,
    });
  } catch (e) {
    debugPrint('SCAM SCAN SAVE FAILED: $e');
  }
}
String? _extractFirstUrl(String input) {
  final urlRegex = RegExp(
    r'((https?:\/\/)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(\/[^\s]*)?)',
  );

  final match = urlRegex.firstMatch(input);

  if (match == null) {
    return null;
  }

  final url = match.group(0);

  if (url == null || url.isEmpty) {
    return null;
  }

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  return 'https://$url';
}
Future<Map<String, dynamic>?> _checkUrlWithSafeBrowsing(String url) async {
  try {
    final response = await _supabase.functions.invoke(
      'check-safe-browsing',
      body: {
        'url': url,
      },
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return data;
    }

    return Map<String, dynamic>.from(data as Map);
  } catch (e) {
    debugPrint('SAFE BROWSING CHECK FAILED: $e');
    return null;
  }
}

  Future<void> _analyzeInput() async {
    final input = _inputController.text.trim();
    final lowerInput = input.toLowerCase();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste a message, link, or profile first'),
        ),
      );
      return;
    }

    int score = 0;
    final List<String> reasons = [];
    final List<String> tips = [];

    final urgentWords = [
      'urgent',
      'immediately',
      'last warning',
      'within 24 hours',
      'act now',
      'final notice',
      'limited time',
      'hurry',
      'deadline',
    ];

    final moneyWords = [
      'send money',
      'payment',
      'bkash',
      'bikash',
      'nagad',
      'rocket',
      'bank account',
      'transfer',
      'fee',
      'advance',
      'registration fee',
      'deposit',
    ];

    final credentialWords = [
      'password',
      'otp',
      'pin',
      'verification code',
      'login',
      'account locked',
      'confirm your account',
      'verify your account',
      'security code',
      'reset your account',
    ];

    final threatWords = [
      'i will harm',
      'blackmail',
      'leak your photo',
      'leak your video',
      'share your picture',
      'kill',
      'attack',
      'threat',
      'expose you',
      'ruin your life',
      'send your photo',
    ];

    final suspiciousLinks = [
      'bit.ly',
      'tinyurl',
      't.ly',
      'shorturl',
      'freegift',
      'claim-now',
      'verify-login',
      'telegram',
      'wa.me',
      'unknown',
      'gift',
      'bonus',
    ];

    for (final word in urgentWords) {
      if (lowerInput.contains(word)) {
        score += 15;
        reasons.add('Uses urgent or pressure-based language.');
        break;
      }
    }

    for (final word in moneyWords) {
      if (lowerInput.contains(word)) {
        score += 20;
        reasons.add('Mentions money, payment, or financial transfer.');
        break;
      }
    }

    for (final word in credentialWords) {
      if (lowerInput.contains(word)) {
        score += 25;
        reasons.add('Asks for private login, OTP, PIN, or account details.');
        break;
      }
    }

    for (final word in threatWords) {
      if (lowerInput.contains(word)) {
        score += 35;
        reasons.add('Contains threatening or blackmail-related language.');
        break;
      }
    }

    if (lowerInput.contains('http://') || lowerInput.contains('https://')) {
      score += 15;
      reasons.add('Contains an external link.');
    }

   final extractedUrl = _extractFirstUrl(input);

if (extractedUrl != null) {
  final safeBrowsingResult = await _checkUrlWithSafeBrowsing(extractedUrl);

  if (safeBrowsingResult != null &&
      safeBrowsingResult['success'] == true) {
    final isUnsafe = safeBrowsingResult['isUnsafe'] == true;

    if (isUnsafe) {
      score += 45;
      reasons.add(
        'Google Safe Browsing found this link in an unsafe threat list.',
      );
    } else {
      reasons.add(
        'Google Safe Browsing did not find this link in known unsafe lists.',
      );
    }
  } else {
    reasons.add(
      'Link safety API could not be checked, so local warning signs were used.',
    );
  }
}

    if (lowerInput.contains('job') &&
        (lowerInput.contains('registration fee') ||
            lowerInput.contains('advance payment') ||
            lowerInput.contains('training fee'))) {
      score += 25;
      reasons.add('Looks like a possible fake job or advance-fee scam.');
    }

    if (lowerInput.contains('prize') ||
        lowerInput.contains('winner') ||
        lowerInput.contains('lottery') ||
        lowerInput.contains('free iphone') ||
        lowerInput.contains('reward')) {
      score += 20;
      reasons.add('Mentions prize, lottery, reward, or free gift claim.');
    }

    if (_selectedType == 'Profile' &&
        (lowerInput.contains('investment') ||
            lowerInput.contains('crypto') ||
            lowerInput.contains('double your money') ||
            lowerInput.contains('guaranteed income'))) {
      score += 25;
      reasons.add('Profile contains suspicious investment or guaranteed income language.');
    }

    ScamRiskLevel level;

    if (score >= 60) {
      level = ScamRiskLevel.dangerous;
      tips.add('Do not reply to this sender.');
      tips.add('Do not click any link or send money.');
      tips.add('Do not share OTP, password, PIN, or personal photos.');
      tips.add('Save this as evidence if it feels threatening.');
      tips.add('Block and report the sender if needed.');
    } else if (score >= 25) {
      level = ScamRiskLevel.suspicious;
      tips.add('Verify the sender before responding.');
      tips.add('Do not share private codes or financial details.');
      tips.add('Avoid clicking links from unknown sources.');
      tips.add('Ask someone trusted before taking action.');
    } else {
      level = ScamRiskLevel.safe;
      reasons.add('No strong scam or threat pattern was found.');
      tips.add('Still be careful if the sender is unknown.');
      tips.add('Never share OTP, passwords, PINs, or private documents.');
      tips.add('Check the sender identity before trusting links.');
    }

    final finalScore = score.clamp(0, 100);
final finalReasons = reasons.toSet().toList();

setState(() {
  _riskLevel = level;
  _riskScore = finalScore;
  _reasons = finalReasons;
  _safetyTips = tips;
});

_saveScanResult(
  scannedContent: input,
  level: level,
  score: finalScore,
  reasons: finalReasons,
  safetyTips: tips,
);
  }

  Color get _riskColor {
    switch (_riskLevel) {
      case ScamRiskLevel.safe:
        return const Color(0xFF7ED9A6);
      case ScamRiskLevel.suspicious:
        return const Color(0xFFE6B15A);
      case ScamRiskLevel.dangerous:
        return const Color(0xFFE96E63);
      default:
        return _caramel;
    }
  }

  String get _riskTitle {
    switch (_riskLevel) {
      case ScamRiskLevel.safe:
        return 'Looks Safe';
      case ScamRiskLevel.suspicious:
        return 'Suspicious';
      case ScamRiskLevel.dangerous:
        return 'Dangerous';
      default:
        return 'Ready to Inspect';
    }
  }

  String get _riskSubtitle {
    switch (_riskLevel) {
      case ScamRiskLevel.safe:
        return 'No major warning signs were found.';
      case ScamRiskLevel.suspicious:
        return 'Some warning signs need attention.';
      case ScamRiskLevel.dangerous:
        return 'High-risk scam or threat pattern detected.';
      default:
        return 'Paste suspicious content and run a safety scan.';
    }
  }

  IconData get _riskIcon {
    switch (_riskLevel) {
      case ScamRiskLevel.safe:
        return Icons.verified_user_rounded;
      case ScamRiskLevel.suspicious:
        return Icons.warning_amber_rounded;
      case ScamRiskLevel.dangerous:
        return Icons.gpp_bad_rounded;
      default:
        return Icons.shield_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _espresso,
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(context),
                  const SizedBox(height: 30),
                  _heroHeader(),
                  const SizedBox(height: 24),
                  _typeSelector(),
                  const SizedBox(height: 18),
                  _inputCard(),
                  const SizedBox(height: 20),
                  _analyzeButton(),
                  const SizedBox(height: 22),
                  _resultCard(),
                  if (_riskLevel != null) ...[
                    const SizedBox(height: 18),
                    _reasonCard(),
                    const SizedBox(height: 18),
                    _tipsCard(),
                  ],
                  
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
          Positioned(
            top: 95,
            left: 30,
            child: _tinyGlow(),
          ),
          Positioned(
            bottom: 160,
            left: 55,
            child: _tinyGlow(size: 8, opacity: 0.22),
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

  Widget _tinyGlow({double size = 6, double opacity = 0.3}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _cream.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        _glassCircleButton(
  icon: Icons.history_rounded,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScamScanHistoryScreen(),
      ),
    );
  },
),
        const Spacer(),
        Text(
          'Scam Detector',
          style: GoogleFonts.poppins(
            color: _cream,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        _glassCircleButton(
          icon: Icons.info_outline_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _heroHeader() {
    return _glassContainer(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      radius: 34,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7B4A36),
                  Color(0xFFE1A46F),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _caramel.withOpacity(0.26),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_police_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Inspect',
            style: GoogleFonts.playfairDisplay(
              color: _cream,
              fontSize: 45,
              fontWeight: FontWeight.w800,
              height: 1.02,
            ),
          ),
          Text(
            'scams & threats',
            style: GoogleFonts.playfairDisplay(
              color: _caramel,
              fontSize: 41,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              height: 1.04,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Paste suspicious messages, links, or profiles. Amaan checks warning signs and gives clear safety advice.',
            style: GoogleFonts.poppins(
              color: _softCream.withOpacity(0.86),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeSelector() {
    return Row(
      children: [
        _typeChip('Message', Icons.mark_chat_unread_rounded),
        const SizedBox(width: 10),
        _typeChip('Link', Icons.link_rounded),
        const SizedBox(width: 10),
        _typeChip('Profile', Icons.person_search_rounded),
      ],
    );
  }

  Widget _typeChip(String title, IconData icon) {
    final selected = _selectedType == title;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = title;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(vertical: 13),
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
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? _caramel.withOpacity(0.35)
                  : Colors.white.withOpacity(0.11),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _caramel.withOpacity(0.17),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? _cream : _softCream.withOpacity(0.72),
                size: 20,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: selected ? _cream : _softCream.withOpacity(0.72),
                  fontSize: 11.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputCard() {
    return _glassContainer(
      padding: const EdgeInsets.all(18),
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.content_paste_search_rounded,
                color: _caramel,
                size: 22,
              ),
              const SizedBox(width: 9),
              Text(
                'Paste $_selectedType',
                style: GoogleFonts.poppins(
                  color: _cream,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _inputController,
            maxLines: 7,
            style: GoogleFonts.poppins(
              color: _cream,
              fontSize: 13,
              height: 1.48,
            ),
            cursorColor: _caramel,
            decoration: InputDecoration(
              hintText:
                  'Paste suspicious text, unknown link, or profile bio here...',
              hintStyle: GoogleFonts.poppins(
                color: _softCream.withOpacity(0.42),
                fontSize: 12.5,
                height: 1.45,
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.19),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: _caramel,
                  width: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
       Row(
  children: [
    _miniUtilityButton(
      icon: Icons.cleaning_services_rounded,
      label: 'Clear Input',
      onTap: () {
        _inputController.clear();
        setState(() {
          _riskLevel = null;
          _riskScore = 0;
          _reasons = [];
          _safetyTips = [];
        });
      },
    ),
  ],
),
        ],
      ),
    );
  }

  Widget _miniUtilityButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.09),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _softCream.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: _softCream.withOpacity(0.82),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _analyzeButton() {
    return GestureDetector(
      onTap: _analyzeInput,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF5A3427),
              Color(0xFF9A6040),
              Color(0xFFE1A46F),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _caramel.withOpacity(0.25),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.radar_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Analyze Safety Risk',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultCard() {
    return _glassContainer(
      padding: const EdgeInsets.all(18),
      radius: 32,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _riskColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _riskColor.withOpacity(0.42),
              ),
              boxShadow: [
                BoxShadow(
                  color: _riskColor.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _riskIcon,
              color: _riskColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _riskTitle,
                  style: GoogleFonts.poppins(
                    color: _cream,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _riskSubtitle,
                  style: GoogleFonts.poppins(
                    color: _softCream.withOpacity(0.70),
                    fontSize: 12.3,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (_riskLevel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: _riskColor.withOpacity(0.13),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _riskColor.withOpacity(0.28),
                ),
              ),
              child: Text(
                '$_riskScore%',
                style: GoogleFonts.poppins(
                  color: _riskColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reasonCard() {
    return _glassContainer(
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.manage_search_rounded, 'Detection Reasons'),
          const SizedBox(height: 14),
          ..._reasons.map(_bulletLine),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    return _glassContainer(
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.health_and_safety_rounded, 'Safety Advice'),
          const SizedBox(height: 14),
          ..._safetyTips.map(_bulletLine),
        ],
      ),
    );
  }

 
  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          color: _caramel,
          size: 21,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: _cream,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _bulletLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: _riskColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: _softCream.withOpacity(0.78),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
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
