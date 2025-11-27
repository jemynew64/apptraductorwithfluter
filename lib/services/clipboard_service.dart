import 'dart:async';
import 'package:flutter/services.dart';

/// Servicio de monitoreo del portapapeles (GRATIS)
/// Monitorea cambios en el portapapeles usando polling
class ClipboardService {
  Function(String)? _onTextCopied;
  String _lastClipboard = '';
  Timer? _timer;
  bool _isWatching = false;

  /// Inicia el monitoreo del portapapeles
  void startWatching({required Function(String) onTextCopied}) {
    if (_isWatching) return;
    
    _onTextCopied = onTextCopied;
    _isWatching = true;
    
    // Revisa el portapapeles cada 2 segundos
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _checkClipboard();
    });
    
    print('✅ Monitoreo de portapapeles iniciado');
  }

  /// Detiene el monitoreo
  void stopWatching() {
    _timer?.cancel();
    _timer = null;
    _isWatching = false;
    print('🛑 Monitoreo de portapapeles detenido');
  }

  /// Revisa si hay cambios en el portapapeles
  Future<void> _checkClipboard() async {
    if (!_isWatching) return;
    
    try {
      print('🔍 Revisando portapapeles...'); // Log para debugging
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipboardData?.text ?? '';
      
      print('📝 Contenido actual: ${text.isEmpty ? "(vacío)" : text.substring(0, text.length > 30 ? 30 : text.length)}');

      if (text.isNotEmpty && text != _lastClipboard) {
        print('🆕 CAMBIO DETECTADO en portapapeles!');
        _lastClipboard = text;
        print('📋 Texto copiado: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
        
        if (_onTextCopied != null) {
          print('🔄 Llamando callback de traducción...');
          _onTextCopied!(text);
        } else {
          print('⚠️ Callback es null!');
        }
      }
    } catch (e) {
      print('❌ Error al leer portapapeles: $e');
    }
  }

  /// Obtiene el contenido actual del portapapeles
  Future<String> getCurrentClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text ?? '';
    } catch (e) {
      print('❌ Error al leer portapapeles: $e');
      return '';
    }
  }

  /// Copia texto al portapapeles
  Future<void> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      print('✅ Texto copiado al portapapeles');
    } catch (e) {
      print('❌ Error al copiar: $e');
    }
  }
}
