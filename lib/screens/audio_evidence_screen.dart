import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';
import 'dart:io';
import '../services/local_audio_evidence_service.dart';

class AudioEvidenceScreen extends StatefulWidget {
  const AudioEvidenceScreen({super.key});

  @override
  State<AudioEvidenceScreen> createState() => _AudioEvidenceScreenState();
}

class _AudioEvidenceScreenState extends State<AudioEvidenceScreen> {
  final LocalAudioEvidenceService _localAudioEvidenceService =
      LocalAudioEvidenceService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<LocalAudioEvidence> _savedAudioEvidenceList = [];
  String? _playingPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEvidence();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadEvidence() async {
    final savedList = await _localAudioEvidenceService.getSavedAudioEvidence();

    if (!mounted) return;

    setState(() {
      _savedAudioEvidenceList = savedList;
      _loading = false;
    });
  }

  Future<void> _playOrPause(LocalAudioEvidence evidence) async {
    try {
      if (_playingPath == evidence.filePath && _audioPlayer.playing) {
        await _audioPlayer.pause();

        if (!mounted) return;

        setState(() {
          _playingPath = null;
        });

        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.setFilePath(evidence.filePath);

      if (!mounted) return;

      setState(() {
        _playingPath = evidence.filePath;
      });

      await _audioPlayer.play();

      if (!mounted) return;

      setState(() {
        _playingPath = null;
      });

      await _audioPlayer.seek(Duration.zero);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _playingPath = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not play audio: $e')),
      );
    }
  }

  String _formatEvidenceDate(LocalAudioEvidence evidence) {
  if (evidence.createdAt.trim().isEmpty) {
    return "Saved audio evidence";
  }

  final parsedDate = DateTime.tryParse(evidence.createdAt);

  if (parsedDate == null) {
    return evidence.createdAt;
  }

  return "${parsedDate.day.toString().padLeft(2, '0')}/"
      "${parsedDate.month.toString().padLeft(2, '0')}/"
      "${parsedDate.year}  "
      "${parsedDate.hour.toString().padLeft(2, '0')}:"
      "${parsedDate.minute.toString().padLeft(2, '0')}";
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F0),
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: _glowBlob(const Color(0xFFFFB3A7), 230),
          ),
          Positioned(
            bottom: -130,
            left: -120,
            child: _glowBlob(const Color(0xFFFFD8B8), 280),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                    Row(
  children: [
    _circleButton(
      icon: Icons.arrow_back_ios_new_rounded,
      onTap: () => Navigator.pop(context),
    ),
  ],
),
                  const SizedBox(height: 34),
                  Text(
  "Audio Evidence",
  style: GoogleFonts.poppins(
    color: const Color(0xFF2B2733),
    fontSize: 34,
    height: 1.05,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.8,
  ),
),
const SizedBox(height: 8),
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
  decoration: BoxDecoration(
    color: const Color(0xFFFFF1EE),
    borderRadius: BorderRadius.circular(100),
    border: Border.all(
      color: const Color(0xFFFFC7BD),
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.graphic_eq_rounded,
        color: Color(0xFFFF5B6B),
        size: 16,
      ),
      const SizedBox(width: 7),
      Text(
        "Emergency recordings",
        style: GoogleFonts.poppins(
          color: const Color(0xFFFF5B6B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  ),
),
                  const SizedBox(height: 16),
                  Text(
                    "Saved emergency recordings are kept here privately for later review.",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8B7B78),
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _privacyCard(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        "RECENT AUDIO",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9A817C),
                          fontSize: 12,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "${_savedAudioEvidenceList.length} saved",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFFF7FA8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF7FA8),
                        ),
                      ),
                    )
                  else if (_savedAudioEvidenceList.isEmpty)
                    _emptyVault()
                  else
                    ..._savedAudioEvidenceList.map(
                      (evidence) => _audioCard(evidence),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _privacyCard() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.96),
              const Color(0xFFFFF1EC).withOpacity(0.78),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.96),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8A7A).withOpacity(0.13),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.75),
              blurRadius: 12,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF6B9A),
                    Color(0xFFFFB3CC),
                  ],
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A7A).withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Private & timestamped",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2B2733),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Each saved audio file stays available inside your evidence vault.",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8B7B78),
                      fontSize: 11.8,
                      height: 1.35,
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
  );
}

 Widget _emptyVault() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.96),
              const Color(0xFFFFF1EC).withOpacity(0.78),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.96),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8A7A).withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.75),
              blurRadius: 12,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF0EC),
                    Color(0xFFFFC9C0),
                  ],
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 1.6,
                ),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFFFF5B6B),
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "No audio evidence saved yet",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF2B2733),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "When Panic Alert records audio, your saved evidence will appear here.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: const Color(0xFF8B7B78),
                fontSize: 12.2,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _audioCard(LocalAudioEvidence evidence) {
    final isPlaying = _playingPath == evidence.filePath && _audioPlayer.playing;

    return GestureDetector(
      onTap: () => _playOrPause(evidence),
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          color: Colors.white.withOpacity(0.10),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                gradient: const LinearGradient(
                  colors: [
  Color(0xFFFF6B9A),
  Color(0xFFFFA8C4),
],
                ),
              ),
              child: Icon(
                isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evidence.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatEvidenceDate(evidence),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.45),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

 Widget _circleButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.86),
                Colors.white.withOpacity(0.46),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.92),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8A7A).withOpacity(0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xFF7B6765),
            size: 23,
          ),
        ),
      ),
    ),
  );
}
  Widget _glowBlob(Color color, double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.28),
      ),
    );
  }
}
