import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio de traducción 100% GRATUITO
/// Usa 2 APIs gratuitas con fallback automático:
/// 1. LibreTranslate (principal) 
/// 2. MyMemory API (backup)
class TranslationService {
  // APIs GRATUITAS (sin registro ni API key)
  static const String _libreTranslateUrl = 'https://libretranslate.com/translate';
  static const String _myMemoryUrl = 'https://api.mymemory.translated.net/get';
  
  /// Traduce texto de inglés a español (100% GRATIS)
  /// Prueba automáticamente 2 servicios gratuitos
  /// 
  /// [text] - Texto a traducir
  /// [sourceLang] - Idioma origen (por defecto 'en')
  /// [targetLang] - Idioma destino (por defecto 'es')
  Future<String> translate({
    required String text,
    String sourceLang = 'en',
    String targetLang = 'es',
  }) async {
    if (text.trim().isEmpty) {
      return '';
    }

    // Limpiar texto
    final cleanedText = text.trim();
    if (cleanedText.length > 500) {
      // Limitar a 500 caracteres para APIs gratuitas
      return await translate(
        text: cleanedText.substring(0, 500) + '...',
        sourceLang: sourceLang,
        targetLang: targetLang,
      );
    }

    // Intentar LibreTranslate primero
    String? result = await _translateLibre(cleanedText, sourceLang, targetLang);
    if (result != null) {
      print('✅ Traducido con LibreTranslate');
      return result;
    }

    // Si falla, usar MyMemory como backup
    result = await _translateMyMemory(cleanedText, sourceLang, targetLang);
    if (result != null) {
      print('✅ Traducido con MyMemory (backup)');
      return result;
    }

    return '❌ Ambos servicios no disponibles - Intenta más tarde';
  }

  /// Intenta traducir con LibreTranslate (Método 1)
  Future<String?> _translateLibre(String text, String source, String target) async {
    try {
      final response = await http.post(
        Uri.parse(_libreTranslateUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'q': text,
          'source': source,
          'target': target,
          'format': 'text',
          'api_key': '', // Vacío = gratis
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText'];
      } else {
        print('⚠️ LibreTranslate error ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ LibreTranslate falló: $e');
      return null;
    }
  }

  /// Intenta traducir con MyMemory API (Método 2 - Backup)
  Future<String?> _translateMyMemory(String text, String source, String target) async {
    try {
      final langPair = '$source|$target';
      final uri = Uri.parse(_myMemoryUrl).replace(
        queryParameters: {
          'q': text,
          'langpair': langPair,
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw Exception('Timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['responseStatus'] == 200) {
          return data['responseData']['translatedText'];
        } else {
          print('⚠️ MyMemory error: ${data['responseStatus']}');
          return null;
        }
      } else {
        print('⚠️ MyMemory HTTP error ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('⚠️ MyMemory falló: $e');
      return null;
    }
  }

  /// Detecta si el texto está en inglés (simple detección)
  bool isEnglish(String text) {
    // Palabras comunes en inglés
    final commonEnglishWords = [
      'the', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had',
      'do', 'does', 'did', 'will', 'would', 'should', 'can', 'could', 'may',
      'might', 'must', 'shall', 'a', 'an', 'and', 'or', 'but', 'if', 'then',
      'this', 'that', 'these', 'those', 'what', 'which', 'who', 'when', 'where',
      'why', 'how', 'all', 'each', 'every', 'both', 'few', 'more', 'most',
      'other', 'some', 'such', 'no', 'nor', 'not', 'only', 'own', 'same', 'so',
      'than', 'too', 'very', 'you', 'your', 'my', 'me', 'we', 'us', 'he', 'she',
      'it', 'they', 'them', 'his', 'her', 'its', 'their'
    ];

    final lowerText = text.toLowerCase();
    
    // Contar palabras en inglés
    int englishWordCount = 0;
    for (final word in commonEnglishWords) {
      if (lowerText.contains(' $word ') || 
          lowerText.startsWith('$word ') || 
          lowerText.endsWith(' $word')) {
        englishWordCount++;
      }
    }

    // Si encuentra más de 2 palabras comunes en inglés, probablemente es inglés
    return englishWordCount >= 2;
  }

  /// Limpia el texto antes de traducir
  String cleanText(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Múltiples espacios a uno solo
        .replaceAll(RegExp(r'[^\w\s.,!?¿¡\-áéíóúñÁÉÍÓÚÑ]'), ''); // Eliminar caracteres raros
  }
}
