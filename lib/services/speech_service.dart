import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

/// Servicio de voz GRATUITO (Speech-to-Text y Text-to-Speech)
class SpeechService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isInitialized = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  /// Inicializa el servicio de voz
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => print('❌ Error STT: $error'),
        onStatus: (status) => print('📢 Estado STT: $status'),
      );

      if (_isInitialized) {
        // Configurar TTS para español
        await _flutterTts.setLanguage('es-ES');
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        
        print('✅ Servicios de voz inicializados');
      }

      return _isInitialized;
    } catch (e) {
      print('❌ Error al inicializar voz: $e');
      return false;
    }
  }

  /// Escucha voz y convierte a texto (inglés)
  Future<void> startListening({
    required Function(String) onResult,
    String language = 'en_US',
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isInitialized) {
      print('❌ Servicio de voz no inicializado');
      return;
    }

    _isListening = true;

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          _isListening = false;
        }
      },
      localeId: language,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );

    print('🎤 Escuchando...');
  }

  /// Detiene la escucha
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      print('🛑 Escucha detenida');
    }
  }

  /// Lee texto en voz alta (Text-to-Speech)
  Future<void> speak(String text, {String language = 'es-ES'}) async {
    try {
      await _flutterTts.setLanguage(language);
      await _flutterTts.speak(text);
      print('🔊 Reproduciendo: $text');
    } catch (e) {
      print('❌ Error al reproducir: $e');
    }
  }

  /// Detiene la reproducción
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Obtiene idiomas disponibles
  Future<List<String>> getAvailableLanguages() async {
    try {
      final locales = await _speechToText.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      return ['en_US', 'es_ES'];
    }
  }

  /// Limpia recursos
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
  }
}
