import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<String> startRecording() async {
    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    final directory = await getApplicationDocumentsDirectory();

    final filePath =
        '${directory.path}/panic_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );

    print('AUDIO STEP 1: recording started');
    print('Audio file path: $filePath');

    return filePath;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();

    print('AUDIO STEP 2: recording stopped');
    print('Saved audio path: $path');

    return path;
  }

  Future<bool> isRecording() async {
    return _recorder.isRecording();
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
