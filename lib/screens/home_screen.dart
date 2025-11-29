import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/translation_service.dart';
import '../services/clipboard_service.dart';
import '../services/speech_service.dart';
import '../services/ocr_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.traductor.flotante/overlay');
  
  String _originalText = '';
  String _translatedText = '';
  bool _isTranslating = false;
  bool _isClipboardActive = false;
  bool _isListening = false;
  bool _overlayActive = false;
  bool _autoSpeakEnabled = false; // 🔊 Lectura automática de traducciones
  
  // Modo Manga
  bool _mangaModeActive = false;
  bool _scrollServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupMethodChannelHandler();
    _checkScrollServiceStatus();
  }

  // Configurar listener para capturas de pantalla desde la burbuja
  void _setupMethodChannelHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onScreenCaptured') {
        final String? imagePath = call.arguments as String?;
        if (imagePath != null) {
          await _processScreenCapture(imagePath);
        }
      } else if (call.method == 'onMangaModeChanged') {
        final bool isActive = call.arguments as bool;
        setState(() {
          _mangaModeActive = isActive;
        });
      }
    });
  }
  
  // Verificar si el servicio de accesibilidad está habilitado
  Future<void> _checkScrollServiceStatus() async {
    try {
      final bool isEnabled = await platform.invokeMethod('isScrollServiceEnabled');
      final bool isMangaModeActive = await platform.invokeMethod('isMangaModeActive');
      setState(() {
        _scrollServiceEnabled = isEnabled;
        _mangaModeActive = isMangaModeActive;
      });
    } catch (e) {
      print('Error verificando servicio: $e');
    }
  }
  
  // Abrir configuración de accesibilidad
  Future<void> _openScrollServiceSettings() async {
    try {
      await platform.invokeMethod('openScrollServiceSettings');
    } catch (e) {
      print('Error abriendo configuración: $e');
    }
  }
  
  // Activar/desactivar modo manga
  Future<void> _toggleMangaMode() async {
    if (!_scrollServiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero debes habilitar el servicio de accesibilidad'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (!_overlayActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero activa la burbuja flotante'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    try {
      await platform.invokeMethod('toggleMangaMode');
      await _checkScrollServiceStatus();
    } catch (e) {
      print('Error toggling manga mode: $e');
    }
  }

  Future<void> _requestPermissions() async {
    // Solicitar permisos necesarios
    await [
      Permission.systemAlertWindow,
      Permission.microphone,
    ].request();
  }

  Future<void> _translate(String text, {bool showSnackbar = false}) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _isTranslating = true;
      _originalText = text;
    });

    final translationService = context.read<TranslationService>();
    final cleanedText = translationService.cleanText(text);
    
    final translated = await translationService.translate(
      text: cleanedText,
      sourceLang: 'en',
      targetLang: 'es',
    );

    setState(() {
      _translatedText = translated;
      _isTranslating = false;
    });

    // 🔊 Auto-lectura si está activada (funciona en segundo plano)
    if (_autoSpeakEnabled && !translated.startsWith('❌') && !translated.startsWith('⏳')) {
      await _speakTranslation();
    }

    // Si estamos en modo manga, mostrar overlay nativo
    if (_mangaModeActive && _overlayActive) {
      try {
        await platform.invokeMethod('showTranslation', {
          'originalText': cleanedText,
          'translatedText': translated,
        });
      } catch (e) {
        print('Error mostrando overlay: $e');
      }
    }

    // Mostrar notificación SOLO si se solicita explícitamente (capturas manuales)
    // NO mostrar en traducción de portapapeles para mantener app en segundo plano
    if (showSnackbar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Traducción: ${translated.substring(0, translated.length > 50 ? 50 : translated.length)}...'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _startClipboardMonitoring() async {
    final clipboardService = context.read<ClipboardService>();
    final translationService = context.read<TranslationService>();

    if (!_isClipboardActive) {
      print('🟢 Iniciando monitoreo de portapapeles...');
      clipboardService.startWatching(
        onTextCopied: (text) {
          print('🎯 CALLBACK RECIBIDO con texto: ${text.substring(0, text.length > 30 ? 30 : text.length)}');
          final isEnglish = translationService.isEnglish(text);
          print('🔤 ¿Es inglés? $isEnglish');
          
          if (isEnglish) {
            print('✅ Iniciando traducción desde portapapeles...');
            // Traducir Y MOSTRAR en pantalla CON notificación
            _translate(text, showSnackbar: true);
          } else {
            print('⚠️ Texto no es inglés, ignorando');
          }
        },
      );
      setState(() => _isClipboardActive = true);
      print('✅ Estado de monitoreo actualizado: activo');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 Monitoreo de portapapeles activado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      clipboardService.stopWatching();
      setState(() => _isClipboardActive = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📋 Monitoreo de portapapeles desactivado'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _startVoiceInput() async {
    final speechService = context.read<SpeechService>();
    
    if (!_isListening) {
      setState(() => _isListening = true);
      
      await speechService.startListening(
        onResult: (text) {
          setState(() => _isListening = false);
          _translate(text);
        },
        language: 'en_US',
      );
    } else {
      await speechService.stopListening();
      setState(() => _isListening = false);
    }
  }

  Future<void> _speakTranslation() async {
    if (_translatedText.isNotEmpty) {
      final speechService = context.read<SpeechService>();
      await speechService.speak(_translatedText, language: 'es-ES');
    }
  }

  Future<void> _toggleOverlay() async {
    try {
      if (!_overlayActive) {
        final result = await platform.invokeMethod('showOverlay');
        if (result == true) {
          setState(() => _overlayActive = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔵 Burbuja flotante activada'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        await platform.invokeMethod('hideOverlay');
        setState(() => _overlayActive = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚪ Burbuja flotante desactivada'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      print('Error con overlay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Procesar captura de pantalla (llamado desde burbuja flotante)
  Future<void> _processScreenCapture(String imagePath) async {
    try {
      if (!mounted) return;
      
      setState(() => _isTranslating = true);
      
      final ocrService = context.read<OcrService>();
      final extractedText = await ocrService.extractTextFromImage(imagePath);
      
      if (extractedText.isNotEmpty) {
        await _translate(extractedText, showSnackbar: true);
      } else {
        setState(() => _isTranslating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ No se detectó texto en la imagen'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error en captura OCR: $e');
      setState(() => _isTranslating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al procesar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureAndTranslate() async {
    try {
      // Llamar al método nativo para capturar pantalla
      await platform.invokeMethod('captureScreen');
      // La respuesta llegará por el MethodCallHandler
    } catch (e) {
      print('Error al solicitar captura: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌐 Traductor Flotante'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card con botones principales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Funciones Principales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Botón Burbuja Flotante
                    ElevatedButton.icon(
                      onPressed: _toggleOverlay,
                      icon: Icon(_overlayActive ? Icons.bubble_chart : Icons.bubble_chart_outlined),
                      label: Text(_overlayActive ? 'Desactivar Burbuja' : 'Activar Burbuja Flotante'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _overlayActive ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    if (_overlayActive) ...[
                      const SizedBox(height: 8),
                      Text(
                        '💡 Doble-toca la burbuja para activar Modo Manga',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    
                    // MODO MANGA
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.purple[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Modo Manga',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[900],
                                ),
                              ),
                              const Spacer(),
                              if (_mangaModeActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ACTIVO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Traduce automáticamente cuando dejas de hacer scroll',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Estado del servicio
                          if (!_scrollServiceEnabled) ...[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.orange[900], size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Servicio de accesibilidad no habilitado',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[900],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _openScrollServiceSettings,
                              icon: const Icon(Icons.settings, size: 18),
                              label: const Text('Habilitar Servicio'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                            ),
                          ] else ...[
                            // Botón activar/desactivar modo manga
                            ElevatedButton.icon(
                              onPressed: _toggleMangaMode,
                              icon: Icon(_mangaModeActive ? Icons.pause : Icons.play_arrow),
                              label: Text(_mangaModeActive 
                                  ? 'Desactivar Modo Manga' 
                                  : 'Activar Modo Manga'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mangaModeActive ? Colors.red : Colors.purple,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 40),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(
                            'ℹ️ Uso: 1) Habilita el servicio, 2) Activa la burbuja, 3) Doble-toca la burbuja',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.purple[600],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Botón Auto-Lectura
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _autoSpeakEnabled = !_autoSpeakEnabled);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _autoSpeakEnabled 
                                ? '🔊 Lectura automática activada'
                                : '🔇 Lectura automática desactivada'
                            ),
                            backgroundColor: _autoSpeakEnabled ? Colors.green : Colors.grey,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(_autoSpeakEnabled ? Icons.volume_up : Icons.volume_off),
                      label: Text(_autoSpeakEnabled 
                          ? 'Desactivar Lectura Auto' 
                          : 'Activar Lectura Automática'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _autoSpeakEnabled ? Colors.green : null,
                        padding: const EdgeInsets.all(16),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Botón OCR
                    ElevatedButton.icon(
                      onPressed: _captureAndTranslate,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Capturar y Traducir (OCR)'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Botón Portapapeles
                    ElevatedButton.icon(
                      onPressed: _startClipboardMonitoring,
                      icon: Icon(_isClipboardActive ? Icons.pause : Icons.content_paste),
                      label: Text(_isClipboardActive 
                          ? 'Desactivar Portapapeles' 
                          : 'Activar Monitoreo Portapapeles'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isClipboardActive ? Colors.green : null,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Botón Voz
                    ElevatedButton.icon(
                      onPressed: _startVoiceInput,
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      label: Text(_isListening ? 'Escuchando...' : 'Traducir por Voz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? Colors.red : null,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Texto original
            if (_originalText.isNotEmpty) ...[
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.language, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Original (EN)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _originalText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Traducción
            if (_translatedText.isNotEmpty) ...[
              Card(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue[900]
                    : Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.translate, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Traducción (ES)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: _speakTranslation,
                            icon: const Icon(Icons.volume_up),
                            tooltip: 'Reproducir traducción',
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _translatedText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Indicador de carga
            if (_isTranslating) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
