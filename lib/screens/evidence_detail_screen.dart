import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class EvidenceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> evidence;

  const EvidenceDetailScreen({
    super.key,
    required this.evidence,
  });

  Future<String> _createSignedImageUrl(String filePath) async {
    final supabase = Supabase.instance.client;

    final signedUrl = await supabase.storage
        .from('evidence-vault')
        .createSignedUrl(filePath, 3600);

    return signedUrl;
  }

  @override
  Widget build(BuildContext context) {
    final type = evidence['evidence_type']?.toString() ?? 'message';
    final title = evidence['title']?.toString() ?? 'Saved Evidence';
    final description = evidence['description']?.toString() ?? '';
    final evidenceText = evidence['encrypted_text']?.toString() ?? '';
    final filePath = evidence['file_path']?.toString() ?? '';
    final createdAt = evidence['created_at_bd']?.toString() ?? '';

    final isMessage = type == 'message';
    final isVideo = type == 'video';

    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      body: Stack(
        children: [
          _background(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(context),
                  const SizedBox(height: 30),
                  _headline(isMessage, isVideo),
                  const SizedBox(height: 24),
                  _statusCard(type, createdAt),
                  const SizedBox(height: 22),
                  _evidenceContentCard(
                    isMessage: isMessage,
                    title: title,
                    description: description,
                    evidenceText: evidenceText,
                    filePath: filePath,
                  ),
                  const SizedBox(height: 22),
                  _reportReadyCard(),
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
          'Evidence Details',
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

  Widget _headline(bool isMessage, bool isVideo) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        isMessage
            ? 'Message'
            : isVideo
                ? 'Video'
                : 'Photo',
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
        'Full saved evidence with timestamp and private record details.',
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

  Widget _statusCard(String type, String createdAt) {
    return _glassContainer(
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
              type == 'message'
    ? Icons.message_rounded
    : type == 'video'
        ? Icons.videocam_rounded
        : Icons.image_rounded,
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
                  'Private Evidence Record',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  createdAt.isEmpty
                      ? 'Timestamp not available'
                      : createdAt.split('.').first,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFC7A6FF),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _evidenceContentCard({
    required bool isMessage,
    required String title,
    required String description,
    required String evidenceText,
    required String filePath,
  }) {
    final isVideo = title.toLowerCase().contains('video');
    return _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (isMessage)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.20),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
              child: Text(
                evidenceText.isEmpty ? 'No message text found.' : evidenceText,
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.86),
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
       else if (isVideo)
  filePath.isEmpty
      ? _emptyImageBox()
      : _videoEvidenceBox(filePath)
else
  ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: filePath.isEmpty
        ? _emptyImageBox()
        : FutureBuilder<String>(
            future: _createSignedImageUrl(filePath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 260,
                  width: double.infinity,
                  color: Colors.black.withOpacity(0.20),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFC7A6FF),
                    ),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return _emptyImageBox();
              }

              return Image.network(
                snapshot.data!,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _emptyImageBox();
                },
              );
            },
          ),
  ),
        ],
      ),
    );
  }

  Widget _emptyImageBox() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.black.withOpacity(0.20),
      child: Center(
        child: Text(
          'No image available yet',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.55),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
  Widget _videoEvidenceBox(String filePath) {
  return FutureBuilder<String>(
    future: _createSignedImageUrl(filePath),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container(
          height: 260,
          width: double.infinity,
          color: Colors.black.withOpacity(0.20),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFC7A6FF),
            ),
          ),
        );
      }

      if (snapshot.hasError || !snapshot.hasData) {
        return _emptyImageBox();
      }

      return _VideoEvidencePlayer(videoUrl: snapshot.data!);
    },
  );
}

  Widget _reportReadyCard() {
    return _glassContainer(
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: Color(0xFFC7A6FF),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This evidence is saved with a timestamp and can be accessed later if needed for reporting.',
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.68),
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
class _VideoEvidencePlayer extends StatefulWidget {
  final String videoUrl;

  const _VideoEvidencePlayer({
    required this.videoUrl,
  });

  @override
  State<_VideoEvidencePlayer> createState() => _VideoEvidencePlayerState();
}

class _VideoEvidencePlayerState extends State<_VideoEvidencePlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideo;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    _initializeVideo = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeVideo,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 260,
            width: double.infinity,
            color: Colors.black.withOpacity(0.20),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC7A6FF),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 220,
            width: double.infinity,
            color: Colors.black.withOpacity(0.20),
            child: Center(
              child: Text(
                'Could not load video',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.60),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
