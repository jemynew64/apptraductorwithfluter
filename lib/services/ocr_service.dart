import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Servicio OCR GRATUITO usando Google ML Kit
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  /// Recorta imagen a la región central del contenido (elimina headers/footers/margins)
  /// 
  /// [imagePath] - Ruta de la imagen original
  /// [topCrop] - Porcentaje superior a eliminar (URLs, headers) - default 0.10 (10%)
  /// [bottomCrop] - Porcentaje inferior a eliminar (footer, navigation) - default 0.15 (15%)
  /// [sideCrop] - Porcentaje lateral a eliminar por cada lado (watermarks) - default 0.05 (5%)
  Future<File> _cropImageToContentArea(
    String imagePath, {
    double topCrop = 0.10,
    double bottomCrop = 0.15,
    double sideCrop = 0.05,
  }) async {
    try {
      // Leer imagen original
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        print('⚠️ No se pudo decodificar la imagen');
        return File(imagePath);
      }

      // Calcular dimensiones del recorte
      final width = image.width;
      final height = image.height;
      
      final cropX = (width * sideCrop).toInt();
      final cropY = (height * topCrop).toInt();
      final cropWidth = (width * (1 - 2 * sideCrop)).toInt();
      final cropHeight = (height * (1 - topCrop - bottomCrop)).toInt();

      print('📐 Imagen original: ${width}x${height}');
      print('✂️ Recortando a región central: ${cropWidth}x${cropHeight}');
      print('   - Eliminando superior: ${(topCrop * 100).toStringAsFixed(0)}% (URLs/headers)');
      print('   - Eliminando inferior: ${(bottomCrop * 100).toStringAsFixed(0)}% (footer/nav)');
      print('   - Eliminando laterales: ${(sideCrop * 100).toStringAsFixed(0)}% por lado (watermarks)');

      // Recortar imagen
      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropWidth,
        height: cropHeight,
      );

      // Guardar imagen recortada temporalmente
      final croppedPath = imagePath.replaceAll('.png', '_cropped.png');
      await File(croppedPath).writeAsBytes(img.encodePng(cropped));

      print('✅ Imagen recortada guardada: $croppedPath');
      return File(croppedPath);
    } catch (e) {
      print('⚠️ Error al recortar imagen, usando original: $e');
      return File(imagePath);
    }
  }

  /// Extrae texto de una imagen usando ML Kit (GRATIS)
  /// Primero recorta la imagen a la región central del contenido
  /// 
  /// [imagePath] - Ruta de la imagen a procesar
  Future<String> extractTextFromImage(String imagePath) async {
    File? croppedFile;
    try {
      // Recortar imagen a región de contenido (diálogos centrales)
      croppedFile = await _cropImageToContentArea(imagePath);

      // Procesar imagen recortada con OCR
      final inputImage = InputImage.fromFile(croppedFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Limpiar archivo temporal si es diferente del original
      if (croppedFile.path != imagePath) {
        try {
          await croppedFile.delete();
          print('🗑️ Archivo temporal eliminado');
        } catch (e) {
          print('⚠️ No se pudo eliminar temporal: $e');
        }
      }

      if (recognizedText.text.isEmpty) {
        return '';
      }

      return recognizedText.text;
    } catch (e) {
      print('❌ Error en OCR: $e');
      
      // Limpiar archivo temporal en caso de error
      if (croppedFile != null && croppedFile.path != imagePath) {
        try {
          await croppedFile.delete();
        } catch (_) {}
      }
      
      return '';
    }
  }

  /// Extrae texto de un archivo File
  /// Primero recorta la imagen a la región central del contenido
  Future<String> extractTextFromFile(File imageFile) async {
    File? croppedFile;
    try {
      // Recortar imagen a región de contenido
      croppedFile = await _cropImageToContentArea(imageFile.path);

      // Procesar imagen recortada con OCR
      final inputImage = InputImage.fromFile(croppedFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Limpiar archivo temporal si es diferente del original
      if (croppedFile.path != imageFile.path) {
        try {
          await croppedFile.delete();
          print('🗑️ Archivo temporal eliminado');
        } catch (e) {
          print('⚠️ No se pudo eliminar temporal: $e');
        }
      }

      if (recognizedText.text.isEmpty) {
        return '';
      }

      return recognizedText.text;
    } catch (e) {
      print('❌ Error en OCR: $e');
      
      // Limpiar archivo temporal en caso de error
      if (croppedFile != null && croppedFile.path != imageFile.path) {
        try {
          await croppedFile.delete();
        } catch (_) {}
      }
      
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
