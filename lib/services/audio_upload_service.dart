import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AudioUploadResult {
  final String storagePath;
  final String localFileName;

  AudioUploadResult({
    required this.storagePath,
    required this.localFileName,
  });
}

class AudioUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AudioUploadResult> uploadAudioEvidence({
    required String filePath,
    String? panicAlertId,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Audio file not found on phone');
    }

    final localFileName = filePath.split('/').last;

    final storagePath =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$localFileName';

    await _supabase.storage.from('panic-audio').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            contentType: 'audio/mp4',
            upsert: false,
          ),
        );

    await _supabase.from('panic_audio_evidence').insert({
      'user_id': user.id,
      'panic_alert_id': panicAlertId,
      'local_file_name': localFileName,
      'storage_bucket': 'panic-audio',
      'storage_path': storagePath,
      'upload_status': 'uploaded',
    });

    debugPrint('AUDIO UPLOAD STEP: uploaded to panic-audio/$storagePath');

    return AudioUploadResult(
      storagePath: storagePath,
      localFileName: localFileName,
    );
  }
}
