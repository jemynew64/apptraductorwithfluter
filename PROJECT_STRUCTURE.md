# 📂 Estructura del Proyecto - Traductor Flotante

```
flutter_app_traducctorpantallas/
│
├── 📄 README.md                          # Documentación completa
├── 📄 QUICKSTART.md                      # Guía rápida de inicio
├── 📄 TECHNICAL_NOTES.md                 # Notas técnicas avanzadas
├── 📄 COMMANDS.md                        # Lista de comandos útiles
├── 📄 pubspec.yaml                       # Dependencias del proyecto
├── 📄 analysis_options.yaml              # Configuración de análisis
│
├── 📁 lib/                               # Código Dart/Flutter
│   ├── 📄 main.dart                      # Punto de entrada, Provider setup
│   │
│   ├── 📁 screens/                       # Pantallas de la UI
│   │   └── 📄 home_screen.dart           # Pantalla principal con botones
│   │
│   └── 📁 services/                      # Lógica de negocio (100% GRATIS)
│       ├── 📄 translation_service.dart   # LibreTranslate API
│       ├── 📄 ocr_service.dart           # Google ML Kit OCR
│       ├── 📄 clipboard_service.dart     # Monitoreo de portapapeles
│       └── 📄 speech_service.dart        # Speech-to-Text y TTS
│
├── 📁 android/                           # Configuración Android
│   ├── 📁 app/
│   │   ├── 📄 build.gradle.kts           # Config: minSdk 24, targetSdk 34
│   │   │
│   │   └── 📁 src/main/
│   │       ├── 📄 AndroidManifest.xml    # Permisos (overlay, micrófono, etc)
│   │       │
│   │       ├── 📁 kotlin/com/example/flutter_app_traducctorpantallas/
│   │       │   └── 📄 MainActivity.kt    # Overlay + MediaProjection
│   │       │
│   │       └── 📁 res/
│   │           ├── 📁 layout/
│   │           │   └── 📄 floating_bubble.xml  # Diseño de la burbuja
│   │           │
│   │           └── 📁 mipmap/
│   │               └── 🖼️ ic_launcher.png      # Ícono de la app
│   │
│   ├── 📄 build.gradle.kts               # Config de Gradle
│   ├── 📄 gradle.properties              # Propiedades de Gradle
│   └── 📄 settings.gradle.kts            # Settings de Gradle
│
├── 📁 ios/                               # (No usado - solo Android)
├── 📁 web/                               # (No usado - solo Android)
├── 📁 windows/                           # (No usado - solo Android)
├── 📁 linux/                             # (No usado - solo Android)
├── 📁 macos/                             # (No usado - solo Android)
│
└── 📁 test/                              # Tests unitarios
    └── 📄 widget_test.dart               # Tests de widgets
```

---

## 🔑 Archivos Clave

### 1️⃣ **lib/main.dart**
- Punto de entrada de la app
- Configuración de Provider (gestión de estado)
- Tema Material 3 con modo claro/oscuro

### 2️⃣ **lib/screens/home_screen.dart**
- Pantalla principal de la UI
- Botones para:
  - Activar/desactivar burbuja flotante
  - Capturar pantalla con OCR
  - Activar monitoreo de portapapeles
  - Traducir por voz
- Mostrar texto original y traducción

### 3️⃣ **lib/services/translation_service.dart**
- **API:** LibreTranslate (https://libretranslate.com)
- **Función:** Traducir texto EN→ES
- **Método:** POST request HTTP
- **Costo:** ✅ GRATIS

### 4️⃣ **lib/services/ocr_service.dart**
- **Tecnología:** Google ML Kit Text Recognition
- **Función:** Extraer texto de imágenes
- **Método:** On-device (local)
- **Costo:** ✅ GRATIS

### 5️⃣ **lib/services/clipboard_service.dart**
- **Plugin:** clipboard_watcher
- **Función:** Detectar texto copiado
- **Método:** Listener de eventos
- **Costo:** ✅ GRATIS

### 6️⃣ **lib/services/speech_service.dart**
- **Plugins:** 
  - `speech_to_text` (voz → texto)
  - `flutter_tts` (texto → voz)
- **Función:** Traducir por voz
- **Método:** On-device
- **Costo:** ✅ GRATIS

### 7️⃣ **android/app/src/main/kotlin/.../MainActivity.kt**
- **Lenguaje:** Kotlin
- **Funciones:**
  - Crear burbuja flotante con WindowManager
  - Capturar pantalla con MediaProjection
  - Comunicación Flutter ↔ Kotlin (MethodChannel)
- **APIs:** Android nativas

### 8️⃣ **android/app/src/main/AndroidManifest.xml**
- **Permisos:**
  - `SYSTEM_ALERT_WINDOW` (burbuja)
  - `INTERNET` (traducción)
  - `RECORD_AUDIO` (voz)
  - `FOREGROUND_SERVICE_MEDIA_PROJECTION` (captura)

### 9️⃣ **android/app/src/main/res/layout/floating_bubble.xml**
- **Diseño:** CardView circular con ícono
- **Tamaño:** 60dp × 60dp
- **Color:** Azul (#2196F3)
- **Interacción:** Arrastrable y clickeable

### 🔟 **android/app/build.gradle.kts**
- **minSdk:** 24 (Android 7.0)
- **targetSdk:** 34 (Android 14)
- **Dependencies:** CardView, Material Components

---

## 🎯 Flujo de Datos

### Captura OCR:
```
Usuario toca burbuja
    ↓
MainActivity.kt captura pantalla (MediaProjection)
    ↓
Guarda imagen en cache
    ↓
Envía ruta a Flutter (MethodChannel)
    ↓
OcrService.dart extrae texto (ML Kit)
    ↓
TranslationService.dart traduce (LibreTranslate)
    ↓
HomeScreen muestra resultado
```

### Traducción por Portapapeles:
```
Usuario copia texto en otra app
    ↓
ClipboardService detecta cambio
    ↓
Verifica si es inglés
    ↓
TranslationService traduce
    ↓
HomeScreen muestra resultado
```

### Traducción por Voz:
```
Usuario presiona botón de micrófono
    ↓
SpeechService escucha (speech_to_text)
    ↓
Convierte voz a texto
    ↓
TranslationService traduce
    ↓
HomeScreen muestra resultado
    ↓
Usuario presiona 🔊 → flutter_tts reproduce
```

---

## 📦 Dependencias (pubspec.yaml)

### Producción:
```yaml
google_mlkit_text_recognition: ^0.13.0  # OCR
http: ^1.2.0                            # Traducción API
clipboard_watcher: ^0.2.0               # Portapapeles
speech_to_text: ^7.0.0                  # Voz → Texto
flutter_tts: ^4.2.0                     # Texto → Voz
permission_handler: ^11.3.0             # Permisos
provider: ^6.1.1                        # Estado
```

### Desarrollo:
```yaml
flutter_test: sdk: flutter
flutter_lints: ^6.0.0
```

---

## 🚀 Tamaño del Proyecto

### APK Estimado:
- **Debug:** ~80 MB
- **Release:** ~40 MB
- **Release (split-per-abi):** ~25 MB por arquitectura

### Líneas de Código:
- **Dart:** ~800 líneas
- **Kotlin:** ~300 líneas
- **XML:** ~100 líneas
- **Total:** ~1,200 líneas

---

## 🔧 Configuración de Compilación

### Debug:
```bash
flutter build apk --debug
# Incluye símbolos de debug, no optimizado
```

### Release:
```bash
flutter build apk --release
# Optimizado, ofuscado, listo para distribución
```

### Split (más pequeño):
```bash
flutter build apk --split-per-abi
# Genera APKs separados por arquitectura
```

---

## 🎨 Recursos Visuales

### Colores:
- Primario: Azul (#2196F3)
- Acento: Naranja (para burbuja activa)
- Fondo: Blanco / Gris oscuro (según tema)

### Íconos:
- Burbuja: `@android:drawable/ic_menu_translate`
- OCR: `Icons.camera_alt`
- Portapapeles: `Icons.content_paste`
- Voz: `Icons.mic`
- Volumen: `Icons.volume_up`

---

## 🧩 Arquitectura

```
┌─────────────────────────────────────────┐
│           UI Layer (Flutter)             │
│  ┌─────────────────────────────────┐    │
│  │      HomeScreen (Widgets)        │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│     Business Logic (Services)            │
│  ┌──────────┐  ┌──────────┐             │
│  │Translation│  │    OCR    │             │
│  │  Service  │  │  Service  │             │
│  └──────────┘  └──────────┘             │
│  ┌──────────┐  ┌──────────┐             │
│  │Clipboard │  │  Speech   │             │
│  │  Service │  │  Service  │             │
│  └──────────┘  └──────────┘             │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│      Native Layer (Kotlin/Android)       │
│  ┌─────────────────────────────────┐    │
│  │  MainActivity (Method Channel)   │    │
│  │  • WindowManager (Overlay)       │    │
│  │  • MediaProjection (Captura)     │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│       External APIs (Gratuitas)          │
│  • LibreTranslate API (Traducción)      │
│  • Google ML Kit (OCR on-device)        │
│  • Android Speech API (Voz on-device)   │
└─────────────────────────────────────────┘
```

---

## ✅ Checklist de Archivos Importantes

- [x] `lib/main.dart` - ✅ Configurado
- [x] `lib/screens/home_screen.dart` - ✅ Completo
- [x] `lib/services/translation_service.dart` - ✅ LibreTranslate
- [x] `lib/services/ocr_service.dart` - ✅ ML Kit
- [x] `lib/services/clipboard_service.dart` - ✅ Implementado
- [x] `lib/services/speech_service.dart` - ✅ STT + TTS
- [x] `android/app/src/main/kotlin/.../MainActivity.kt` - ✅ Overlay
- [x] `android/app/src/main/AndroidManifest.xml` - ✅ Permisos
- [x] `android/app/src/main/res/layout/floating_bubble.xml` - ✅ Diseño
- [x] `android/app/build.gradle.kts` - ✅ Config
- [x] `pubspec.yaml` - ✅ Dependencias
- [x] `README.md` - ✅ Documentación
- [x] `QUICKSTART.md` - ✅ Guía rápida
- [x] `TECHNICAL_NOTES.md` - ✅ Notas técnicas
- [x] `COMMANDS.md` - ✅ Comandos útiles

---

**🎉 Proyecto 100% completo y listo para compilar!**
