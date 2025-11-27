import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Servicio OCR GRATUITO usando Google ML Kit
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Extrae texto de una imagen usando ML Kit (GRATIS)
  /// 
  /// [imagePath] - Ruta de la imagen a procesar
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return '';
      }

      return recognizedText.text;
    } catch (e) {
      print('❌ Error en OCR: $e');
      return '';
    }
  }

  /// Extrae texto de un archivo File
  Future<String> extractTextFromFile(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return '';
      }

      return recognizedText.text;
    } catch (e) {
      print('❌ Error en OCR: $e');
      return '';
    }
  }

  /// Extrae bloques de texto con su posición (útil para selección)
  Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      return recognizedText.blocks;
    } catch (e) {
      print('❌ Error al extraer bloques: $e');
      return [];
    }
  }

  /// Filtra solo texto en inglés de los bloques extraídos
  String filterEnglishText(List<TextBlock> blocks) {
    final englishPattern = RegExp(r'[a-zA-Z]');
    final buffer = StringBuffer();

    for (final block in blocks) {
      final text = block.text;
      if (englishPattern.hasMatch(text)) {
        buffer.writeln(text);
      }
    }

    return buffer.toString().trim();
  }

  /// Limpia recursos del reconocedor
  void dispose() {
    _textRecognizer.close();
  }
}
