import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("pt-BR");
    await _flutterTts.setSpeechRate(0.5); // Mais lento para crianças entenderem
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.1); // Voz levemente mais aguda/animada
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
