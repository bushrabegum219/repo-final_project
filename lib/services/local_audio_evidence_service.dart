import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class LocalAudioEvidence {
  final String filePath;
  final String fileName;
  final String createdAt;

  LocalAudioEvidence({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'createdAt': createdAt,
    };
  }

  factory LocalAudioEvidence.fromJson(Map<String, dynamic> json) {
    return LocalAudioEvidence(
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class LocalAudioEvidenceService {
  static const String _storageKey = 'saved_audio_evidence_list';

  Future<void> saveAudioEvidence(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Audio file does not exist on phone');
    }

    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList(_storageKey) ?? [];

    final evidence = LocalAudioEvidence(
      filePath: filePath,
      fileName: filePath.split('/').last,
      createdAt: DateTime.now().toIso8601String(),
    );

    currentList.insert(0, jsonEncode(evidence.toJson()));

    await prefs.setStringList(_storageKey, currentList);
  }

  Future<List<LocalAudioEvidence>> getSavedAudioEvidence() async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = prefs.getStringList(_storageKey) ?? [];

    final evidenceList = <LocalAudioEvidence>[];

    for (final item in currentList) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final evidence = LocalAudioEvidence.fromJson(decoded);

        if (await File(evidence.filePath).exists()) {
          evidenceList.add(evidence);
        }
      } catch (_) {
        continue;
      }
    }

    return evidenceList;
  }
}
