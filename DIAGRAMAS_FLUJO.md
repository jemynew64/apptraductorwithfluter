# 🔄 Diagramas de Flujo - Traductor Flotante

## 📱 Flujo Principal de la Aplicación

```
┌──────────────────────────────────────────────┐
│          Usuario abre la app                 │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────────┐
│       HomeScreen (Pantalla Principal)        │
│  ┌────────────────────────────────────────┐  │
│  │  [🔵 Activar Burbuja Flotante]         │  │
│  │  [📸 Capturar y Traducir (OCR)]        │  │
│  │  [📋 Activar Monitoreo Portapapeles]   │  │
│  │  [🎤 Traducir por Voz]                 │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

---

## 🔵 Flujo: Burbuja Flotante

```
Usuario presiona "Activar Burbuja Flotante"
    │
    ▼
¿Tiene permiso SYSTEM_ALERT_WINDOW?
    │
    ├─ NO → Redirige a Configuración de permisos
    │        │
    │        ▼
    │    Usuario concede permiso
    │        │
    └─ SÍ ──┴─► MainActivity.kt crea overlay
                    │
                    ▼
            WindowManager.addView(overlayView)
                    │
                    ▼
            Burbuja aparece en pantalla (movible)
                    │
                    ▼
        ┌───────────┴───────────┐
        │                       │
    Usuario mueve           Usuario toca
    la burbuja              la burbuja
        │                       │
        ▼                       ▼
    Se actualiza          Captura pantalla
    posición XY           (OCR automático)
```

---

## 📸 Flujo: OCR (Captura y Traducción)

```
Usuario toca burbuja flotante / presiona botón OCR
    │
    ▼
¿Tiene permiso FOREGROUND_SERVICE_MEDIA_PROJECTION?
    │
    ├─ NO → Solicita permiso (diálogo del sistema)
    │        │
    │        ▼
    │    Usuario acepta
    │        │
    └─ SÍ ──┴─► MainActivity.kt inicia MediaProjection
                    │
                    ▼
            mediaProjectionManager.createScreenCaptureIntent()
                    │
                    ▼
            Captura pantalla actual
                    │
                    ▼
            Guarda imagen en cache (PNG)
                    │
                    ▼
            Envía ruta a Flutter (MethodChannel)
                    │
                    ▼
    ┌───────────────┴───────────────┐
    │   OcrService.dart             │
    │   Google ML Kit Text Recognition │
    └───────────────┬───────────────┘
                    │
                    ▼
            Extrae texto de la imagen
                    │
                    ▼
            Filtra texto en inglés (regex)
                    │
                    ▼
    ┌───────────────┴───────────────┐
    │   TranslationService.dart     │
    │   LibreTranslate API          │
    └───────────────┬───────────────┘
                    │
                    ▼
            POST https://libretranslate.com/translate
            Body: { q: "text", source: "en", target: "es" }
                    │
                    ▼
            Recibe traducción en español
                    │
                    ▼
            HomeScreen muestra resultado:
            ┌─────────────────────────┐
            │ Original (EN):          │
            │ "Hello World"           │
            ├─────────────────────────┤
            │ Traducción (ES):        │
            │ "Hola Mundo"            │
            │           [🔊 Reproducir]│
            └─────────────────────────┘
```

---

## 📋 Flujo: Monitoreo de Portapapeles

```
Usuario presiona "Activar Monitoreo Portapapeles"
    │
    ▼
ClipboardService.startWatching()
    │
    ▼
clipboardWatcher.addListener()
    │
    ▼
┌──────────────────────────────────┐
│   Escuchando cambios en          │
│   portapapeles (background)      │
└──────────────┬───────────────────┘
               │
               ▼
Usuario copia texto en CUALQUIER app
(WhatsApp, Chrome, Juegos, etc.)
               │
               ▼
ClipboardService detecta cambio
               │
               ▼
¿El texto es diferente al anterior?
    │
    ├─ NO → Ignora (evita duplicados)
    │
    └─ SÍ → ¿El texto está en inglés?
                │
                ├─ NO → Ignora
                │
                └─ SÍ → TranslationService.translate()
                            │
                            ▼
                        POST a LibreTranslate API
                            │
                            ▼
                        Muestra traducción automáticamente
                            │
                            ▼
                    ┌───────────────────────┐
                    │ 📋 Texto copiado      │
                    │ detectado y traducido │
                    │ automáticamente       │
                    └───────────────────────┘
```

---

## 🎤 Flujo: Traducción por Voz

```
Usuario presiona "Traducir por Voz"
    │
    ▼
¿Tiene permiso RECORD_AUDIO?
    │
    ├─ NO → Solicita permiso
    │        │
    │        ▼
    │    Usuario acepta
    │        │
    └─ SÍ ──┴─► SpeechService.initialize()
                    │
                    ▼
            SpeechToText.initialize()
                    │
                    ▼
            FlutterTts.setLanguage('es-ES')
                    │
                    ▼
        ┌───────────┴───────────┐
        │   Micrófono activado  │
        │   🔴 ESCUCHANDO...    │
        └───────────┬───────────┘
                    │
                    ▼
        Usuario habla en inglés:
        "Hello, how are you?"
                    │
                    ▼
        speech_to_text convierte a texto
        (on-device, gratis)
                    │
                    ▼
        Texto reconocido: "Hello, how are you?"
                    │
                    ▼
        TranslationService.translate()
                    │
                    ▼
        POST a LibreTranslate API
                    │
                    ▼
        Traducción: "Hola, ¿cómo estás?"
                    │
                    ▼
        Muestra en pantalla con botón 🔊
                    │
                    ▼
        Usuario presiona 🔊
                    │
                    ▼
        FlutterTts.speak("Hola, ¿cómo estás?")
                    │
                    ▼
        ┌─────────────────────────┐
        │ 🔊 Reproduciendo audio  │
        │ en español              │
        └─────────────────────────┘
```

---

## 🔄 Flujo: Comunicación Flutter ↔ Kotlin

```
Flutter (Dart)                    Android Native (Kotlin)
═══════════════════════════════════════════════════════════

HomeScreen
    │
    │ Llama:
    │ platform.invokeMethod('showOverlay')
    ▼
MethodChannel                     MainActivity.kt
'com.traductor.                       │
flotante/overlay'                     │
    │                                 ▼
    │ ─────────────────────────────► methodChannel
    │                                 .setMethodCallHandler
    │                                     │
    │                                     ▼
    │                               when (call.method)
    │                                 'showOverlay' ->
    │                                     │
    │                                     ▼
    │                               showFloatingBubble()
    │                                     │
    │                                     ▼
    │                               WindowManager
    │                               .addView(overlayView)
    │                                     │
    │                                     ▼
    │                               Burbuja visible
    │                                     │
    │                               result.success(true)
    │                                     │
    │ ◄─────────────────────────────────┘
    ▼
HomeScreen recibe true
setState(() => _overlayActive = true)
    │
    ▼
Muestra mensaje: "🔵 Burbuja flotante activada"
```

---

## 🌐 Flujo: API de Traducción (LibreTranslate)

```
TranslationService.translate(text: "Hello World")
    │
    ▼
Prepara request HTTP POST
    │
    ▼
┌─────────────────────────────────────────────┐
│  POST https://libretranslate.com/translate  │
│  Headers:                                    │
│    Content-Type: application/json           │
│  Body:                                       │
│    {                                         │
│      "q": "Hello World",                     │
│      "source": "en",                         │
│      "target": "es",                         │
│      "format": "text"                        │
│    }                                         │
└────────────────┬────────────────────────────┘
                 │
                 ▼
        INTERNET (Wi-Fi/Datos)
                 │
                 ▼
┌─────────────────────────────────────────────┐
│      Servidor LibreTranslate (Gratis)       │
│  • Motor de traducción open-source         │
│  • Sin API key                              │
│  • Sin límites estrictos                    │
└────────────────┬────────────────────────────┘
                 │
                 ▼
        Response HTTP 200 OK
                 │
                 ▼
┌─────────────────────────────────────────────┐
│  Response Body:                              │
│  {                                           │
│    "translatedText": "Hola Mundo"           │
│  }                                           │
└────────────────┬────────────────────────────┘
                 │
                 ▼
    Parsea JSON response
                 │
                 ▼
    return "Hola Mundo"
                 │
                 ▼
    HomeScreen muestra resultado
```

---

## 🧠 Flujo: OCR con Google ML Kit (On-Device)

```
OcrService.extractTextFromImage(imagePath)
    │
    ▼
Carga imagen desde archivo
    │
    ▼
┌─────────────────────────────────────────────┐
│      InputImage.fromFilePath()              │
│  • Lee imagen PNG/JPEG                      │
│  • Carga en memoria                         │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│   Google ML Kit Text Recognizer             │
│   (ON-DEVICE - No requiere internet)        │
│  • Modelo de IA local                       │
│  • Script: Latin (inglés, español, etc.)    │
└────────────────┬────────────────────────────┘
                 │
                 ▼
        Procesa imagen pixel por pixel
                 │
                 ▼
        Detecta regiones con texto
                 │
                 ▼
        Reconoce caracteres (OCR)
                 │
                 ▼
        Agrupa en palabras y líneas
                 │
                 ▼
┌─────────────────────────────────────────────┐
│   RecognizedText                            │
│  • text: "Hello World\nWelcome to Game"    │
│  • blocks: [Block1, Block2]                │
│  • lines: [Line1, Line2, Line3]            │
│  • elements: [Word1, Word2, ...]           │
└────────────────┬────────────────────────────┘
                 │
                 ▼
    return recognizedText.text
                 │
                 ▼
    "Hello World\nWelcome to Game"
                 │
                 ▼
    Se envía a TranslationService
```

---

## 🎭 Flujo: Ciclo de Vida de la App

```
App iniciada
    │
    ▼
main.dart → runApp(TraductorFlotanteApp)
    │
    ▼
MultiProvider setup
    ├─ TranslationService
    ├─ OcrService
    ├─ ClipboardService
    └─ SpeechService
    │
    ▼
MaterialApp con tema
    │
    ▼
HomeScreen (StatefulWidget)
    │
    ▼
initState()
    ├─ _requestPermissions()
    │   ├─ SYSTEM_ALERT_WINDOW
    │   └─ RECORD_AUDIO
    │
    ▼
build() → UI renderizada
    │
    ├──► Usuario interactúa con botones
    │    ├─ Activar burbuja
    │    ├─ OCR
    │    ├─ Portapapeles
    │    └─ Voz
    │
    ├──► setState() actualiza UI
    │
    └──► Servicios procesan en background
         │
         └──► Resultados mostrados en UI

Usuario cierra app
    │
    ▼
onDestroy()
    ├─ Detiene monitoreo de portapapeles
    ├─ Cierra servicios de voz
    ├─ Libera recursos de OCR
    └─ Elimina burbuja flotante (si activa)
```

---

## 🔐 Flujo: Gestión de Permisos

```
App solicita permiso
    │
    ▼
┌─────────────────────────────────────┐
│  Tipo de permiso?                   │
└───────┬─────────────────────────────┘
        │
        ├─► SYSTEM_ALERT_WINDOW (Overlay)
        │       │
        │       ▼
        │   if (Build.VERSION >= M)
        │       │
        │       ├─ checkOverlayPermission()
        │       │   ├─ Sí → Continuar
        │       │   └─ No → requestOverlayPermission()
        │       │           │
        │       │           ▼
        │       │       Abre configuración del sistema
        │       │       (Configuración → Apps → Permisos)
        │       │           │
        │       │           ▼
        │       │       Usuario concede manualmente
        │       │           │
        │       │           ▼
        │       │       onActivityResult()
        │       │           │
        │       │           ▼
        │       │       Verifica nuevamente
        │
        ├─► RECORD_AUDIO (Micrófono)
        │       │
        │       ▼
        │   Permission.microphone.request()
        │       │
        │       ▼
        │   Diálogo del sistema aparece
        │       │
        │       ├─ Usuario acepta → granted
        │       └─ Usuario rechaza → denied
        │
        └─► FOREGROUND_SERVICE_MEDIA_PROJECTION
                │
                ▼
            startActivityForResult(captureIntent)
                │
                ▼
            Diálogo del sistema
            "¿Permitir captura de pantalla?"
                │
                ├─ Usuario acepta → RESULT_OK
                └─ Usuario rechaza → RESULT_CANCELED
```

---

## 📊 Flujo de Datos Completo (End-to-End)

```
┌─────────────────────────────────────────────────────┐
│                  USUARIO FINAL                      │
│  (Jugando un juego en inglés en Android)           │
└────────────────────┬────────────────────────────────┘
                     │
                     │ Toca burbuja flotante
                     ▼
┌─────────────────────────────────────────────────────┐
│             CAPA NATIVA (Kotlin)                    │
│  MainActivity.kt                                     │
│  • MediaProjection captura pantalla                 │
│  • Guarda imagen PNG en cache                       │
│  • MethodChannel envía ruta a Flutter              │
└────────────────────┬────────────────────────────────┘
                     │
                     │ Ruta del archivo imagen
                     ▼
┌─────────────────────────────────────────────────────┐
│          CAPA DE SERVICIOS (Dart)                   │
│  OcrService.dart                                     │
│  • Google ML Kit procesa imagen (on-device)         │
│  • Extrae texto: "Attack the enemy castle"         │
└────────────────────┬────────────────────────────────┘
                     │
                     │ Texto en inglés
                     ▼
┌─────────────────────────────────────────────────────┐
│          CAPA DE SERVICIOS (Dart)                   │
│  TranslationService.dart                            │
│  • Envía request HTTP a LibreTranslate             │
│  • Recibe: "Ataca el castillo enemigo"             │
└────────────────────┬────────────────────────────────┘
                     │
                     │ Texto traducido
                     ▼
┌─────────────────────────────────────────────────────┐
│               CAPA DE UI (Flutter)                  │
│  HomeScreen.dart                                     │
│  • setState() actualiza UI                          │
│  • Muestra texto original y traducción             │
└────────────────────┬────────────────────────────────┘
                     │
                     │ UI actualizada
                     ▼
┌─────────────────────────────────────────────────────┐
│                  USUARIO FINAL                      │
│  Ve en pantalla:                                    │
│  ┌───────────────────────────────────────────────┐ │
│  │ Original (EN): Attack the enemy castle        │ │
│  │ Traducción (ES): Ataca el castillo enemigo 🔊 │ │
│  └───────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

---

## ⏱️ Timeline de Ejecución (Tiempos típicos)

```
T=0ms      Usuario toca burbuja
           │
T=50ms     MainActivity recibe evento
           │
T=100ms    Inicia MediaProjection
           │
T=200ms    Captura completada, imagen en cache
           │
T=250ms    MethodChannel envía ruta a Flutter
           │
T=300ms    OcrService inicia procesamiento
           │
T=800ms    ML Kit completa OCR (on-device)
           │
T=850ms    TranslationService envía request HTTP
           │
T=1500ms   LibreTranslate responde (depende de internet)
           │
T=1550ms   setState() actualiza UI
           │
T=1600ms   Usuario ve la traducción
           │
           ✅ TOTAL: ~1.6 segundos
```

---

**📝 Nota:** Estos diagramas muestran el flujo real implementado en el proyecto. Todos los tiempos son aproximados y pueden variar según el dispositivo y conexión a internet.
