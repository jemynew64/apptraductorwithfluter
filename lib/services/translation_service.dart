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

    // Limpiar texto ANTES de todo
    final cleanedText = cleanText(text);
    
    if (cleanedText.isEmpty) {
      print('⚠️ Texto vacío después de limpieza - solo contenía URLs/basura');
      return '';
    }
    
    // Validar que tenga contenido real (al menos 15 caracteres de texto válido)
    if (cleanedText.length < 15) {
      print('⚠️ Texto muy corto después de limpieza: "$cleanedText"');
      return '';
    }
    
    if (cleanedText.length > 500) {
      // Limitar a 500 caracteres para APIs gratuitas
      return await translate(
        text: cleanedText.substring(0, 500) + '...',
        sourceLang: sourceLang,
        targetLang: targetLang,
      );
    }

    print('📝 Texto a traducir: "$cleanedText"');

    // Intentar LibreTranslate primero
    String? result = await _translateLibre(cleanedText, sourceLang, targetLang);
    if (result != null && result.isNotEmpty) {
      print('✅ Traducido con LibreTranslate');
      return result;
    }

    // Si falla, usar MyMemory como backup
    result = await _translateMyMemory(cleanedText, sourceLang, targetLang);
    if (result != null && result.isNotEmpty) {
      print('✅ Traducido con MyMemory (backup)');
      return result;
    }

    return '❌ No se pudo traducir - Intenta capturar de nuevo';
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
    String cleaned = text.trim();
    
    // FILTROS DE CONTENIDO NO DESEADO
    
    // 1. Eliminar URLs completas (http, https, www, .com, .net, etc)
    cleaned = cleaned.replaceAll(
      RegExp(r'(https?://)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(/[^\s]*)?', caseSensitive: false),
      ''
    );
    
    // 2. Eliminar rutas de sitios (manhuaclan.com/manga/xxx)
    cleaned = cleaned.replaceAll(
      RegExp(r'[a-zA-Z0-9-]+\.(com|net|org|co|io)/[^\s]*', caseSensitive: false),
      ''
    );
    
    // 3. Eliminar timestamps y números solos (10:07, 92 7, etc)
    cleaned = cleaned.replaceAll(RegExp(r'\d{1,2}:\d{2}'), ''); // Horas
    cleaned = cleaned.replaceAll(RegExp(r'^\d+\s*\d*$', multiLine: true), ''); // Números solos
    
    // 4. Eliminar palabras comunes de navegación/UI
    final uiWords = [
      'READ FIRST AT',
      'MANHUAPLUS.COM',
      'MANHWAPLUS',
      'MANHUACLAN',
      'CHAPTER',
      'NEXT',
      'PREVIOUS',
      'HOME',
      'BOOKMARK',
      'SEARCH',
      'MENU',
    ];
    for (final word in uiWords) {
      cleaned = cleaned.replaceAll(RegExp(word, caseSensitive: false), '');
    }
    
    // 5. Eliminar líneas muy cortas (menos de 10 caracteres) que suelen ser basura
    final lines = cleaned.split('\n');
    cleaned = lines.where((line) => line.trim().length >= 10).join('\n');
    
    // NORMALIZACIÓN DE TEXTO
    
    // 6. Normalizar mayúsculas: Si TODO está en MAYÚSCULAS, convertir a formato normal
    if (cleaned == cleaned.toUpperCase() && cleaned.length > 10) {
      cleaned = cleaned.toLowerCase();
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'(^|[.!?]\s+)([a-z])'),
        (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}'
      );
      if (cleaned.isNotEmpty) {
        cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
      }
    }
    
    // 7. Limpiar caracteres especiales problemáticos
    cleaned = cleaned
        .replaceAll('Ā', 'A')
        .replaceAll('Ō', 'O')
        .replaceAll('Ū', 'U')
        .replaceAll('Ē', 'E')
        .replaceAll('Ī', 'I')
        .replaceAll('ā', 'a')
        .replaceAll('ō', 'o')
        .replaceAll('ū', 'u')
        .replaceAll('ē', 'e')
        .replaceAll('ī', 'i')
        .replaceAll(''', "'")
        .replaceAll(''', "'")
        .replaceAll('"', '"')
        .replaceAll('"', '"')
        .replaceAll('…', '...');
    
    // 8. Normalizar espacios múltiples y saltos de línea
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // 9. Eliminar caracteres no imprimibles y raros (pero mantener acentos españoles)
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s.,!?¿¡\-áéíóúñÁÉÍÓÚÑüÜ()]'), '');
    
    // 10. Limpiar espacios al inicio/final
    return cleaned.trim();
  }
}
