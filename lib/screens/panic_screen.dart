import 'dart:io';
import '../services/audio_upload_service.dart';
import '../services/local_audio_evidence_service.dart';
import 'live_tracking_viewer_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../services/live_location_tracking_service.dart';

import '../services/audio_recording_service.dart';
import '../services/panic_service.dart';
import 'trusted_contacts_screen.dart';
import '../services/foreground_recording_service.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F8),
      body: SafeArea(
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
                                    width: 114,
                                    height: 114,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFFF3F52),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF3F52)
                                              .withOpacity(0.28),
                                          blurRadius: 28,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _alertSent
                                              ? Icons.warning_amber_rounded
                                              : Icons.shield_outlined,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _alertSent ? "Alert Sent!" : "Ready",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          _alertSent
                                              ? "HELP IS ON THE WAY"
                                              : "TAP PANIC BUTTON TO START",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.2,
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

                      if (_audioSaved && _audioFilePath != null) ...[
                        const SizedBox(height: 12),

                        /// SAVED AUDIO EVIDENCE CARD
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7EE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF9AD4AD),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.audio_file_rounded,
                                    color: Color(0xFF2E7D32),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Saved Audio Evidence",
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF1B5E20),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "File saved and accessible inside this app",
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _audioFilePath!.split('/').last,
                                style: GoogleFonts.poppins(
                                  color: Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: _toggleSavedAudioPlayback,
                                child: Container(
                                  height: 44,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isAudioPlaying
                                            ? Icons
                                                .pause_circle_filled_rounded
                                            : Icons.play_circle_fill_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isAudioPlaying
                                            ? "Pause Saved Audio"
                                            : "Play Saved Audio",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
const SizedBox(height: 10),

GestureDetector(
  onTap: _isUploadingAudio || _audioUploaded
      ? null
      : _uploadSavedAudioEvidence,
  child: Container(
    height: 44,
    width: double.infinity,
    decoration: BoxDecoration(
      color: _audioUploaded
          ? const Color(0xFF1565C0)
          : const Color(0xFFFF5B6B),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _audioUploaded
              ? Icons.cloud_done_rounded
              : Icons.cloud_upload_rounded,
          color: Colors.white,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          _isUploadingAudio
              ? "Uploading..."
              : _audioUploaded
                  ? "Uploaded to Supabase"
                  : "Upload Audio Evidence",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  ),
),

if (_audioUploaded && _uploadedStoragePath != null) ...[
  const SizedBox(height: 8),
  Text(
    "Cloud path: $_uploadedStoragePath",
    style: GoogleFonts.poppins(
      color: Colors.black54,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    ),
  ),
],
if (_savedAudioEvidenceList.isNotEmpty) ...[
  const SizedBox(height: 14),

  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFFE0E0E0),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Saved Evidence Library",
          style: GoogleFonts.poppins(
            color: const Color(0xFF2B2733),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        ..._savedAudioEvidenceList.take(3).map((evidence) {
          return GestureDetector(
            onTap: () {
              setState(() {
                _audioFilePath = evidence.filePath;
                _audioSaved = true;
                _isAudioPlaying = false;
                _audioUploaded = false;
                _uploadedStoragePath = null;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved audio loaded. Tap Play Saved Audio.'),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.audio_file_rounded,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evidence.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Tap to open in player",
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.black45,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  ),
],

                      const SizedBox(height: 18),

                      /// CONTACT HEADER
                      Row(
                        children: [
                          Text(
                            "ALERT RECIPIENTS",
                            style: GoogleFonts.poppins(
                              color: Colors.black38,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _smsSent ? "SMS Sent" : "Waiting",
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFF5B6B),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// CONTACTS
                      Row(
                        children: [
                          _contactItem(
                            name: "Ammu",
                            letter: "A",
                            bgColor: const Color(0xFFDFF4E5),
                            textColor: const Color(0xFF35A76E),
                          ),
                          const SizedBox(width: 18),
                          _contactItem(
                            name: "Baba",
                            letter: "B",
                            bgColor: const Color(0xFF2C2C2C),
                            textColor: Colors.white,
                          ),
                          const SizedBox(width: 18),
                          _contactItem(
                            name: "Appi",
                            letter: "A",
                            bgColor: const Color(0xFFE5E5E5),
                            textColor: const Color(0xFF8A8A8A),
                          ),
                        ],
                      ),

                      const Spacer(),

                      const SizedBox(height: 24),

                      /// STOP RECORDING BUTTON
                      GestureDetector(
                        onTap: _stopRecordingAndSave,
                        child: Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? const Color(0xFFFF434F)
                                : const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (_isRecording)
                                BoxShadow(
                                  color: const Color(0xFFFF434F)
                                      .withOpacity(0.26),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
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
                                          ? Icons
                                              .check_circle_outline_rounded
                                          : Icons.mic_off_rounded,
                                  color: _isRecording
                                      ? Colors.white
                                      : Colors.black45,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isRecording
                                      ? "Stop Recording"
                                      : _audioSaved
                                          ? "Recording Stopped"
                                          : "Recording Not Started",
                                  style: GoogleFonts.poppins(
                                    color: _isRecording
                                        ? Colors.white
                                        : Colors.black45,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// CANCEL EMERGENCY MODE
                      GestureDetector(
                        onTap: _cancelEmergencyMode,
                        child: Text(
                          "Cancel Emergency Mode",
                          style: GoogleFonts.poppins(
                            color: Colors.black45,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: Colors.black54,
        ),
      ),
  
    );
  }
  

  Widget _statusCard({
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.028),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2B2733),
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.black38,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
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
