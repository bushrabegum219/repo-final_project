import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'evidence_library_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'evidence_detail_screen.dart';
class EvidenceVaultScreen extends StatefulWidget {
  const EvidenceVaultScreen({super.key});

  @override
  State<EvidenceVaultScreen> createState() => _EvidenceVaultScreenState();
}

class _EvidenceVaultScreenState extends State<EvidenceVaultScreen> {
  final TextEditingController _messageEvidenceController =
    TextEditingController();
    final SupabaseClient _supabase = Supabase.instance.client;
    final ImagePicker _imagePicker = ImagePicker();
    @override
void dispose() {
  _messageEvidenceController.dispose();
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(height: 34),
                  _headline(),
                  const SizedBox(height: 28),
                  _securityCard(),
                  const SizedBox(height: 22),
                  _addEvidenceCard(),
                  const SizedBox(height: 22),
                  _evidenceTypes(),
                  const SizedBox(height: 22),
                  _recentEvidenceHeader(),
const SizedBox(height: 14),
_recentEvidenceList(),
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
            top: -80,
            right: -70,
            child: _glowCircle(const Color(0xFF8B5CFF), 210),
          ),
          Positioned(
            top: 260,
            left: -110,
            child: _glowCircle(const Color(0xFFFF4D88), 230),
          ),
          Positioned(
            bottom: -90,
            right: -80,
            child: _glowCircle(const Color(0xFF5C7CFF), 220),
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
          'Evidence Vault',
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
          'Secure your',
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
          'Save threatening messages, screenshots, and photos in a private timestamped vault.',
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

  Widget _securityCard() {
    return _glassContainer(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF9B6CFF),
                  Color(0xFFFF6F9F),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private & Timestamped',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each saved item will include date and time for reporting.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 11.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _addEvidenceCard() {
  return GestureDetector(
    
  onTap: () {
    _showAddEvidenceSheet();
  },
  child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8B5CFF),
            Color(0xFFE05C9F),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE05C9F).withOpacity(0.30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.add_photo_alternate_rounded,
                color: Colors.white,
                size: 34,
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Add New Evidence',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Save a message, screenshot, or photo securely.',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.78),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
  void _showAddEvidenceSheet() {
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
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 30),
            decoration: BoxDecoration(
              color: const Color(0xFF201B2E).withOpacity(0.92),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(34),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Add New Evidence',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose what type of evidence you want to save.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),

                _sheetActionTile(
                  icon: Icons.message_rounded,
                  title: 'Save Threatening Message',
                  subtitle: 'Paste or type a message as evidence',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessageEvidenceSheet();
                  },
                ),

                const SizedBox(height: 14),

                _sheetActionTile(
                  icon: Icons.image_rounded,
                  title: 'Save Screenshot / Photo',
                  subtitle: 'Upload an image from gallery',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndSavePhotoEvidence();
                  },
                ),

                const SizedBox(height: 14),

                _sheetActionTile(
                  icon: Icons.videocam_rounded,
                  title: 'Save Video Evidence',
                  subtitle: 'Upload a short video as evidence',
                  onTap: () {
  Navigator.pop(sheetContext);
  _pickAndSaveVideoEvidence();
},
                    
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
Future<void> _pickAndSaveVideoEvidence() async {
  final userId = _supabase.auth.currentUser?.id;

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not logged in')),
    );
    return;
  }

  try {
    final XFile? pickedVideo = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
    );

    if (pickedVideo == null) {
      return;
    }

    final file = File(pickedVideo.path);
    final fileExtension = pickedVideo.path.split('.').last;
    final fileName =
        'video_evidence_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    final filePath = '$userId/$fileName';

    await _supabase.storage.from('evidence-vault').upload(
          filePath,
          file,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    await _supabase.from('evidence_vault_items').insert({
      'user_id': userId,
      'evidence_type': 'video',
      'title': 'Video Evidence',
      'description': 'Saved video evidence',
      'file_path': filePath,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video evidence saved')),
    );

    setState(() {});
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video evidence save failed: $e')),
    );
  }
}
Future<void> _pickAndSavePhotoEvidence() async {
  final userId = _supabase.auth.currentUser?.id;

  if (userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not logged in')),
    );
    return;
  }

  try {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      return;
    }

    final file = File(pickedFile.path);
    final fileExtension = pickedFile.path.split('.').last;
    final fileName =
        'evidence_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    final filePath = '$userId/$fileName';

    await _supabase.storage.from('evidence-vault').upload(
          filePath,
          file,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    await _supabase.from('evidence_vault_items').insert({
      'user_id': userId,
      'evidence_type': 'photo',
      'title': 'Photo / Screenshot Evidence',
      'description': 'Saved photo or screenshot evidence',
      'file_path': filePath,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo evidence saved')),
    );

    setState(() {});
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Photo evidence save failed: $e')),
    );
  }
}
Future<List<Map<String, dynamic>>> _loadRecentEvidenceItems() async {
  final userId = _supabase.auth.currentUser?.id;

  if (userId == null) {
    return [];
  }

  final data = await _supabase
      .from('evidence_vault_items')
      .select()
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(3);

  return List<Map<String, dynamic>>.from(data);
}
Future<void> _saveMessageEvidence() async {
  final messageText = _messageEvidenceController.text.trim();

  if (messageText.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a message first')),
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

  try {
    await _supabase.from('evidence_vault_items').insert({
      'user_id': userId,
      'evidence_type': 'message',
      'title': 'Threatening Message',
      'description': 'Saved text message evidence',
      'encrypted_text': messageText,
    });

    _messageEvidenceController.clear();

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message evidence saved')),
    );

    setState(() {});
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Evidence save failed: $e')),
    );
  }
}
void _showMessageEvidenceSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.60),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(34),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
              decoration: BoxDecoration(
                color: const Color(0xFF171421).withOpacity(0.94),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(34),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Threatening Message',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Paste or type the message you want to preserve as evidence.',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 170,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: TextField(
                      controller: _messageEvidenceController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Paste threatening message here...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: _saveMessageEvidence,
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B5CFF),
                            Color(0xFFE05C9F),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE05C9F).withOpacity(0.28),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Save Message Evidence',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _sheetActionTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF9B6CFF),
                  Color(0xFFFF6F9F),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 23,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.52),
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white.withOpacity(0.45),
            size: 14,
          ),
        ],
      ),
    ),
  );
}

  Widget _evidenceTypes() {
  return Row(
    children: [
      Expanded(
        child: _typeCard(
          icon: Icons.message_rounded,
          title: 'Message',
          subtitle: 'Save text threat',
          onTap: _showMessageEvidenceSheet,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _typeCard(
          icon: Icons.image_rounded,
          title: 'Photo',
          subtitle: 'Screenshot/image',
          onTap: _pickAndSavePhotoEvidence,
        ),
      ),
    ],
  );
}

Widget _typeCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: _glassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFC7A6FF),
            size: 28,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.54),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

  
  Widget _recentEvidenceHeader() {
    return Row(
      children: [
        Text(
          'RECENT EVIDENCE',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.42),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const Spacer(),
        GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EvidenceLibraryScreen(),
      ),
    );
  },
  child: Text(
    'View all',
    style: GoogleFonts.poppins(
      color: const Color(0xFFC7A6FF),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  ),
),
      ],
    );
  }
  Widget _recentEvidenceList() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _loadRecentEvidenceItems(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _glassContainer(
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFC7A6FF),
            ),
          ),
        );
      }

      if (snapshot.hasError) {
        return _glassContainer(
          child: Text(
            'Could not load recent evidence',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.70),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }

      final items = snapshot.data ?? [];

      if (items.isEmpty) {
        return _emptyRecentCard();
      }

      return Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _recentEvidenceCard(item),
          );
        }).toList(),
      );
    },
  );
}

Widget _recentEvidenceCard(Map<String, dynamic> item) {
  final type = item['evidence_type']?.toString() ?? 'message';
  final title = item['title']?.toString() ?? 'Saved Evidence';
  final createdAt = item['created_at_bd']?.toString() ?? '';
  final isMessage = type == 'message';

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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF9B6CFF),
                  Color(0xFFFF6F9F),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isMessage ? Icons.message_rounded : Icons.image_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  createdAt.isEmpty
                      ? 'Timestamp not available'
                      : createdAt.split('.').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFC7A6FF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _emptyRecentCard() {
    return _glassContainer(
      child: Column(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: Colors.white.withOpacity(0.70),
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            'No evidence saved yet',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your saved evidence will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.52),
              fontSize: 12,
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

