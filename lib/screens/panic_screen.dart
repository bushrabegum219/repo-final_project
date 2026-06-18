import 'dart:io';
import '../services/audio_upload_service.dart';
import '../services/local_audio_evidence_service.dart';
import 'live_tracking_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../services/live_location_tracking_service.dart';
import 'audio_evidence_screen.dart';
import 'dart:ui';
import '../services/audio_recording_service.dart';
import '../services/panic_service.dart';
import 'trusted_contacts_screen.dart';
import '../services/foreground_recording_service.dart';
import '../services/trusted_contact_service.dart';

class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  final PanicService _panicService = PanicService();
  final AudioRecordingService _audioRecordingService = AudioRecordingService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioUploadService _audioUploadService = AudioUploadService();
  final LocalAudioEvidenceService _localAudioEvidenceService =
    LocalAudioEvidenceService();
    final ForegroundRecordingService _foregroundRecordingService =
    ForegroundRecordingService();
    final LiveLocationTrackingService _liveLocationTrackingService =
    LiveLocationTrackingService();
    bool _liveTrackingActive = false;
    final TrustedContactService _trustedContactService = TrustedContactService();

List<Map<String, dynamic>> _trustedContacts = [];
bool _trustedContactsLoading = true;
String? _liveTrackingSessionId;
String? _liveTrackingError;

  bool _panicStarted = false;
  bool _alertSent = false;
  bool _isRecording = false;
  bool _locationShared = false;
  bool _smsSent = false;
  bool _audioSaved = false;
  bool _isAudioPlaying = false;
  bool _isUploadingAudio = false;
bool _audioUploaded = false;
String? _uploadedStoragePath;

  String? _audioFilePath;
  List<LocalAudioEvidence> _savedAudioEvidenceList = [];

  Future<void> _toggleSavedAudioPlayback() async {
    if (_audioFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved audio found'),
        ),
      );
      return;
    }

    try {
      if (_isAudioPlaying) {
        await _audioPlayer.pause();

        if (!mounted) return;

        setState(() {
          _isAudioPlaying = false;
        });

        return;
      }

      await _audioPlayer.stop();
      await _liveLocationTrackingService.stopLiveTracking();
      await _audioPlayer.setFilePath(_audioFilePath!);

      if (!mounted) return;

      setState(() {
        _isAudioPlaying = true;
      });

      await _audioPlayer.play();

      if (!mounted) return;

      setState(() {
        _isAudioPlaying = false;
      });

      await _audioPlayer.seek(Duration.zero);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAudioPlaying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not play saved audio: $e'),
        ),
      );
    }
  }

  Future<void> _stopRecordingAndSave() async {
    if (!_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active recording to stop'),
        ),
      );
      return;
    }

    final savedPath = await _audioRecordingService.stopRecording();
    await _foregroundRecordingService.stopService();
    final fileSaved = savedPath != null && await File(savedPath).exists();

    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _audioSaved = fileSaved;
       _audioUploaded = false;
  _uploadedStoragePath = null;
      _audioFilePath = fileSaved ? savedPath : null;
    });
if (fileSaved && savedPath != null) {
  await _localAudioEvidenceService.saveAudioEvidence(savedPath);
  await _loadSavedAudioEvidenceList();
}
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          fileSaved
              ? 'Audio evidence saved on phone'
              : 'Recording stopped, but audio file was not found',
        ),
      ),
    );

    debugPrint('Audio evidence saved at: $_audioFilePath');
  }

 Future<void> _cancelEmergencyMode() async {
  debugPrint('CANCEL STEP: Cancel Emergency Mode tapped');

  await _liveLocationTrackingService.stopLiveTracking();

  debugPrint('CANCEL STEP: live tracking stop requested');

  await _audioPlayer.stop();

  final wasRecording = _isRecording;
  String? savedPath = _audioFilePath;
  bool fileSaved = _audioSaved;

  if (wasRecording) {
    savedPath = await _audioRecordingService.stopRecording();
    await _foregroundRecordingService.stopService();
    fileSaved = savedPath != null && await File(savedPath).exists();

    if (fileSaved && savedPath != null) {
      await _localAudioEvidenceService.saveAudioEvidence(savedPath);
      await _loadSavedAudioEvidenceList();
    }
  } else {
    await _foregroundRecordingService.stopService();
  }

  if (!mounted) return;

  setState(() {
    _panicStarted = false;
    _alertSent = false;
    _locationShared = false;
    _smsSent = false;
    _isRecording = false;
    _isAudioPlaying = false;

    _liveTrackingActive = false;
    _liveTrackingSessionId = null;
    _liveTrackingError = null;

    if (fileSaved && savedPath != null) {
      _audioSaved = true;
      _audioFilePath = savedPath;
    }
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Emergency mode cancelled'),
    ),
  );

  debugPrint('CANCEL STEP: emergency mode cancelled successfully');
}
@override
void initState() {
  super.initState();
  _loadSavedAudioEvidenceList();
  _loadTrustedContactsForPanic();
}
  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecordingService.dispose();
    _liveLocationTrackingService.dispose();
    super.dispose();
  }
  Future<void> _uploadSavedAudioEvidence() async {
  if (_audioFilePath == null || !_audioSaved) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No saved audio available to upload'),
      ),
    );
    return;
  }

  try {
    setState(() {
      _isUploadingAudio = true;
    });

    final result = await _audioUploadService.uploadAudioEvidence(
      filePath: _audioFilePath!,
    );

    if (!mounted) return;

    setState(() {
      _isUploadingAudio = false;
      _audioUploaded = true;
      _uploadedStoragePath = result.storagePath;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Audio evidence uploaded to Supabase'),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isUploadingAudio = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Audio upload failed: $e'),
      ),
    );
  }
}
Future<void> _loadSavedAudioEvidenceList() async {
  final savedList = await _localAudioEvidenceService.getSavedAudioEvidence();

  if (!mounted) return;

  setState(() {
    _savedAudioEvidenceList = savedList;
  });

  debugPrint('Saved audio evidence count: ${savedList.length}');
}

Future<String?> _tryStartLiveTracking() async {
  try {
    final sessionId = await _liveLocationTrackingService.startLiveTracking();
    final trackingToken = _liveLocationTrackingService.activeTrackingToken;

    if (!mounted) return trackingToken;

    setState(() {
      _liveTrackingActive = sessionId != null;
      _liveTrackingSessionId = sessionId;
      _liveTrackingError = null;
    });

    debugPrint('Live tracking started: $sessionId');
    debugPrint('Live tracking token: $trackingToken');

    return trackingToken;
  } catch (e) {
    if (!mounted) return null;

    setState(() {
      _liveTrackingActive = false;
      _liveTrackingSessionId = null;
      _liveTrackingError = e.toString();
    });

    debugPrint('Live tracking not started: $e');

    return null;
  }
}
Future<void> _loadTrustedContactsForPanic() async {
  try {
    final contacts = await _trustedContactService.getTrustedContacts();

    if (!mounted) return;

    setState(() {
      _trustedContacts = contacts;
      _trustedContactsLoading = false;
    });
  } catch (_) {
    try {
      final cachedContacts =
          await _trustedContactService.getCachedTrustedContacts();

      if (!mounted) return;

      setState(() {
        _trustedContacts = cachedContacts;
        _trustedContactsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _trustedContactsLoading = false;
      });
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
  backgroundColor: const Color(0xFFFFF6F0),
      body: Stack(
  children: [
    Positioned(
      top: 95,
      right: -70,
      child: _panicGlowBlob(
        color: const Color(0xFFFFB3A7),
        size: 230,
      ),
    ),
    Positioned(
      top: 390,
      left: -90,
      child: _panicGlowBlob(
        color: const Color(0xFFFFD8B8),
        size: 260,
      ),
    ),
    Positioned(
      bottom: 80,
      right: -80,
      child: _panicGlowBlob(
        color: const Color(0xFFFF9AA2),
        size: 210,
      ),
    ),
    SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      /// TOP BAR
                      Row(
                        children: [
                          _circleButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onTap: () => Navigator.pop(context),
                          ),
                          const Spacer(),
Row(
  children: [
    _circleButton(
      icon: Icons.graphic_eq_rounded,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AudioEvidenceScreen(),
          ),
        );
      },
    ),
    const SizedBox(width: 8),
    _circleButton(
      icon: Icons.contacts_rounded,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TrustedContactsScreen(),
          ),
        );
      },
    ),
    const SizedBox(width: 8),
    _circleButton(
      icon: Icons.my_location_rounded,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LiveTrackingViewerScreen(),
          ),
        );
      },
    ),
  ],
),
],
),
const SizedBox(height: 26),
                      /// ALERT CIRCLE
                      Center(
                        child: Container(
                          width: 210,
                          height: 210,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF4D5E).withOpacity(0.06),
                          ),
                          child: Center(
                            child: Container(
                              width: 162,
                              height: 162,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    const Color(0xFFFF4D5E).withOpacity(0.10),
                              ),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () async {
                                    debugPrint("PANIC BUTTON PRESSED");

                                    try {
                                      await _audioPlayer.stop();
                                      await _foregroundRecordingService.startService();

                                      _audioFilePath =
                                          await _audioRecordingService
                                              .startRecording();

                                      if (!mounted) return;

                                      setState(() {
                                        _isRecording = true;
                                        _audioSaved = false;
                                        _isAudioPlaying = false;
                                      });

                                      debugPrint(
                                        'Audio recording started at: $_audioFilePath',
                                      );
final liveTrackingToken = await _tryStartLiveTracking();

final alertMessage = await _panicService.sendAlert(
  liveTrackingToken: liveTrackingToken,
);
                                      if (!mounted) return;

                                      setState(() {
                                        _panicStarted = true;
                                        _alertSent = true;
                                        _locationShared = true;
                                        _smsSent = true;
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Panic alert sent'),
                                        ),
                                      );

                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text(
                                              'Emergency Alert Sent',
                                            ),
                                            content:
                                                SelectableText(alertMessage),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      debugPrint("PANIC ALERT SAVED");
                                    } catch (error) {
                                      if (!mounted) return;

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Alert failed: $error',
                                          ),
                                        ),
                                      );

                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Alert Failed'),
                                            content:
                                                SelectableText(error.toString()),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                  child: Container(
  width: 132,
  height: 132,
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _alertSent
          ? const [
              Color(0xFFE53935),
              Color(0xFFFF7043),
            ]
          : const [
              Color(0xFFFF385C),
              Color(0xFFFF7A63),
            ],
    ),
    border: Border.all(
      color: Colors.white.withOpacity(0.82),
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFFFF4D5E).withOpacity(0.30),
        blurRadius: 34,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.45),
        blurRadius: 10,
        offset: const Offset(-4, -4),
      ),
    ],
  ),
  child: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _alertSent
              ? Icons.warning_amber_rounded
              : Icons.shield_outlined,
          color: Colors.white,
          size: 29,
        ),
        const SizedBox(height: 7),
        Text(
          _alertSent ? "Alert Sent" : "Ready",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: 92,
          child: Text(
            _alertSent ? "HELP IS ON THE WAY" : "TAP TO START",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.92),
              fontSize: 9.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    ),
  ),
),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// LOCATION STATUS CARD
                      _statusCard(
                        iconBg: _locationShared
                            ? const Color(0xFFE9FFF1)
                            : const Color(0xFFEFEFEF),
                        iconColor: _locationShared
                            ? const Color(0xFF36C980)
                            : Colors.black38,
                        icon: Icons.location_on_rounded,
                        title: _locationShared
                            ? "Location Shared"
                            : "Location Waiting",
                        subtitle: _locationShared
                            ? "Current location link created"
                            : "Will share after panic alert",
                        trailing: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _panicStarted
                                ? const Color(0xFFEAFBF0)
                                : const Color(0xFFEFEFEF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _locationShared
                                ? Icons.check_rounded
                                : Icons.hourglass_empty_rounded,
                            size: 14,
                            color: _panicStarted
                                ? const Color(0xFF5FD38E)
                                : Colors.black38,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// RECORDING STATUS CARD
                      _statusCard(
                        iconBg: _isRecording
                            ? const Color(0xFFFFF0F0)
                            : _audioSaved
                                ? const Color(0xFFEAF7EE)
                                : const Color(0xFFEFEFEF),
                        iconColor: _isRecording
                            ? const Color(0xFFFF8A8A)
                            : _audioSaved
                                ? const Color(0xFF2E7D32)
                                : Colors.black38,
                        icon: Icons.mic_rounded,
                        title: _isRecording
                            ? "Recording Active"
                            : _audioSaved
                                ? "Audio Saved"
                                : "Recording Not Started",
                        subtitle: _isRecording
                            ? "Audio evidence is being saved"
                            : _audioSaved
                                ? "Saved and playable inside this app"
                                : "Will start after panic alert",
                        trailing: Text(
                          _isRecording
                              ? "REC"
                              : _audioSaved
                                  ? "SAVED"
                                  : "--",
                          style: GoogleFonts.poppins(
                            color: _audioSaved
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFFF5B6B),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      

                      const SizedBox(height: 18),

                      
                      /// TRUSTED CONTACTS
_trustedContactsPreview(),

                      const Spacer(),

                      const SizedBox(height: 24),

                      /// STOP RECORDING BUTTON
                      /// STOP RECORDING BUTTON
ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
    child: GestureDetector(
      onTap: _stopRecordingAndSave,
      child: Container(
        height: 58,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: _isRecording
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF385C),
                    Color(0xFFFF7A63),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.92),
                    const Color(0xFFFFF1EC).withOpacity(0.78),
                  ],
                ),
          border: Border.all(
            color: _isRecording
                ? Colors.white.withOpacity(0.85)
                : Colors.white.withOpacity(0.96),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: _isRecording
                  ? const Color(0xFFFF4D5E).withOpacity(0.24)
                  : const Color(0xFFFF8A7A).withOpacity(0.10),
              blurRadius: 24,
              offset: const Offset(0, 13),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isRecording
                    ? Icons.stop_circle_rounded
                    : _audioSaved
                        ? Icons.check_circle_outline_rounded
                        : Icons.mic_off_rounded,
                color: _isRecording
                    ? Colors.white
                    : _audioSaved
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF9A817C),
                size: 21,
              ),
              const SizedBox(width: 9),
              Text(
                _isRecording
                    ? "Stop Recording"
                    : _audioSaved
                        ? "Recording Saved"
                        : "Recording Not Started",
                style: GoogleFonts.poppins(
                  color: _isRecording
                      ? Colors.white
                      : _audioSaved
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF7B6765),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),
                      const SizedBox(height: 12),

                      /// CANCEL EMERGENCY MODE
                      /// CANCEL EMERGENCY MODE
Center(
  child: GestureDetector(
    onTap: _cancelEmergencyMode,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withOpacity(0.86),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.close_rounded,
            color: Color(0xFF9A817C),
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            "Cancel Emergency Mode",
            style: GoogleFonts.poppins(
              color: const Color(0xFF8B7B78),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  ),
),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            );
          },
                ),
      ), // SafeArea
],
), // Stack
); // Scaffold
  }
  Widget _panicGlowBlob({
  required Color color,
  required double size,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(0.20),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.22),
          blurRadius: 80,
          spreadRadius: 18,
        ),
      ],
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
} Widget _trustedContactsPreview() {
  final contactCount = _trustedContacts.length;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFF0EC),
                        Color(0xFFFFC7BD),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.4,
                    ),
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: Color(0xFFFF5B6B),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trusted Contacts",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2B2733),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _trustedContactsLoading
                            ? "Checking contacts"
                            : contactCount == 0
                                ? "No contacts added"
                                : "$contactCount contacts ready",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF9A817C),
                          fontSize: 11.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EE),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color(0xFFFFC7BD),
                    ),
                  ),
                  child: Text(
                    _smsSent ? "SMS Sent" : "Ready",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFFF5B6B),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_trustedContactsLoading)
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF6B6B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Loading your contacts...",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8B7B78),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else if (_trustedContacts.isEmpty)
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TrustedContactsScreen(),
                    ),
                  );
                  _loadTrustedContactsForPanic();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EE),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFC7BD),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFFFF5B6B),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Add trusted contacts",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF7B6765),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFFFF5B6B),
                        size: 14,
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _trustedContacts.take(4).map((contact) {
                          final name =
                              (contact['name'] ?? 'Contact').toString();

                          return Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: _trustedContactBubble(name),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrustedContactsScreen(),
                        ),
                      );
                      _loadTrustedContactsForPanic();
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFF4F1),
                            Color(0xFFFFD6CE),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8A7A).withOpacity(0.16),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFFFF5B6B),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _trustedContactBubble(String name) {
  return Column(
    children: [
      Container(
        width: 50,
        height: 50,
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
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8A7A).withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _initialsFromName(name),
            style: GoogleFonts.poppins(
              color: const Color(0xFFFF5B6B),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      const SizedBox(height: 7),
      SizedBox(
        width: 64,
        child: Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            color: const Color(0xFF6F5D5A),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
String _initialsFromName(String name) {
  final cleanedName = name.trim();

  if (cleanedName.isEmpty) {
    return "?";
  }

  final parts = cleanedName.split(RegExp(r'\s+'));

  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }

  return "${parts.first.characters.first}${parts.last.characters.first}"
      .toUpperCase();
}
    

  Widget _statusCard({
  required Color iconBg,
  required Color iconColor,
  required IconData icon,
  required String title,
  required String subtitle,
  required Widget trailing,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.92),
              Colors.white.withOpacity(0.58),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.95),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF9A8A).withOpacity(0.11),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.70),
              blurRadius: 10,
              offset: const Offset(-4, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    iconBg.withOpacity(0.95),
                    Colors.white.withOpacity(0.68),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF2B2733),
                      fontSize: 13.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8B7B78),
                      fontSize: 11.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing,
          ],
        ),
      ),
    ),
  );
}

  Widget _contactItem({
    required String name,
    required String letter,
    required Color bgColor,
    required Color textColor,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text(
              letter,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: GoogleFonts.poppins(
            color: const Color(0xFF333333),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
