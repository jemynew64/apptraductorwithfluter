import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/translation_service.dart';
import 'services/ocr_service.dart';
import 'services/clipboard_service.dart';
import 'services/speech_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TraductorFlotanteApp());
}

class TraductorFlotanteApp extends StatelessWidget {
  const TraductorFlotanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TranslationService>(
          create: (_) => TranslationService(),
        ),
        Provider<OcrService>(
          create: (_) => OcrService(),
        ),
        Provider<ClipboardService>(
          create: (_) => ClipboardService(),
        ),
        Provider<SpeechService>(
          create: (_) => SpeechService(),
        ),
      ],
      child: MaterialApp(
        title: 'Traductor Flotante',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
