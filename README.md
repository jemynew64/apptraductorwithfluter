# 🌐 Traductor Flotante - App Android Gratuita

**Aplicación Flutter para Android con traducción EN→ES completamente gratuita**

Una app potente y 100% gratuita que te permite traducir texto en inglés a español desde cualquier aplicación o juego usando una burbuja flotante, OCR, portapapeles y reconocimiento de voz.

---

## ✨ Características Principales

### 🔵 Burbuja Flotante
- Overlay que aparece sobre cualquier app (incluido juegos)
- Movible libremente por la pantalla
- Click para activar captura OCR
- Sin servicios de pago

### 📸 OCR Gratuito (Google ML Kit)
- Detección de texto en pantalla con **Google ML Kit** (100% gratis)
- Captura automática con `MediaProjection`
- Extracción de texto en inglés
- Traducción instantánea

### 🌍 Traducción Gratuita EN→ES
- **LibreTranslate API** pública (sin costo, sin límites estrictos)
- Endpoint: `https://libretranslate.com/translate`
- Sin necesidad de API Key
- Traducción inglés → español automática

### 📋 Monitoreo de Portapapeles
- Detecta texto copiado automáticamente
- Traduce texto en inglés al instante
- Sin servicios premium

### 🎤 Reconocimiento de Voz (Speech-to-Text)
- **`speech_to_text`** on-device (gratis)
- Habla en inglés y traduce a español
- **`flutter_tts`** para reproducir traducción

---

## 🛠️ Tecnologías Utilizadas (100% Gratuitas)

| Función | Tecnología | Costo |
|---------|-----------|-------|
| **OCR** | Google ML Kit Text Recognition | ✅ GRATIS |
| **Traducción** | LibreTranslate API | ✅ GRATIS |
| **Voz a Texto** | speech_to_text (on-device) | ✅ GRATIS |
| **Texto a Voz** | flutter_tts | ✅ GRATIS |
| **Portapapeles** | clipboard_watcher | ✅ GRATIS |
| **Overlay** | Android SYSTEM_ALERT_WINDOW | ✅ GRATIS |
| **Captura de Pantalla** | MediaProjection API | ✅ GRATIS |

---

## 📦 Instalación y Configuración

### Requisitos Previos

- **Flutter SDK** >= 3.10.1
- **Android Studio** o VS Code con extensiones de Flutter
- **JDK 17**
- **Android SDK** con nivel 34 (Android 14)
- Dispositivo Android físico o emulador con **Android 7.0+** (API 24+)

### Paso 1: Clonar o Descargar el Proyecto

```bash
git clone <tu-repositorio>
cd flutter_app_traducctorpantallas
```

### Paso 2: Instalar Dependencias

```bash
flutter pub get
```

Esto instalará automáticamente:
- `google_mlkit_text_recognition` (OCR)
- `http` (traducción API)
- `speech_to_text` (voz a texto)
- `flutter_tts` (texto a voz)
- `clipboard_watcher` (portapapeles)
- `permission_handler` (permisos)
- `flutter_overlay_window` (overlay)
- `provider` (gestión de estado)

### Paso 3: Configurar Android

El proyecto ya está configurado con:

#### ✅ AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />
```

#### ✅ build.gradle.kts
```kotlin
minSdk = 24  // Android 7.0+
targetSdk = 34  // Android 14
compileSdk = 34
```

### Paso 4: Compilar el APK

#### Modo Debug (para pruebas)
```bash
flutter build apk --debug
```

#### Modo Release (para producción)
```bash
flutter build apk --release
```

El APK se generará en:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Paso 5: Instalar en Dispositivo Android

```bash
flutter install
```

O instala manualmente el APK desde `build/app/outputs/flutter-apk/`

---

## 🚀 Cómo Usar la App

### 1️⃣ Conceder Permisos

Al abrir la app por primera vez, debes conceder:

- ✅ **Permiso de Overlay** (dibujar sobre otras apps)
- ✅ **Permiso de Micrófono** (para voz a texto)
- ✅ **Permiso de Captura de Pantalla** (para OCR)

### 2️⃣ Activar Burbuja Flotante

1. Presiona **"Activar Burbuja Flotante"**
2. Se mostrará una burbuja azul en la pantalla
3. Puedes moverla arrastrándola con el dedo
4. Funciona sobre cualquier app o juego

### 3️⃣ Capturar y Traducir (OCR)

1. Presiona **"Capturar y Traducir (OCR)"**
2. Acepta el permiso de captura de pantalla
3. La app captura la pantalla automáticamente
4. Detecta texto en inglés con ML Kit
5. Lo traduce a español con LibreTranslate
6. Muestra el resultado en la app

**Desde la burbuja:**
- Toca la burbuja flotante para capturar la pantalla al instante

### 4️⃣ Traducción Automática desde Portapapeles

1. Presiona **"Activar Monitoreo Portapapeles"**
2. Copia cualquier texto en inglés desde otra app
3. La app lo detecta automáticamente
4. Lo traduce a español
5. Muestra la traducción

### 5️⃣ Traducir por Voz

1. Presiona **"Traducir por Voz"**
2. Habla en inglés
3. La app convierte tu voz a texto
4. Lo traduce a español
5. Presiona 🔊 para escuchar la traducción en voz

---

## 📱 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada, configuración Provider
├── screens/
│   └── home_screen.dart        # Pantalla principal con botones
├── services/
│   ├── translation_service.dart  # LibreTranslate API (GRATIS)
│   ├── ocr_service.dart         # Google ML Kit OCR (GRATIS)
│   ├── clipboard_service.dart   # Monitoreo de portapapeles
│   └── speech_service.dart      # Speech-to-Text y TTS (GRATIS)
│
android/
├── app/
│   ├── src/main/
│   │   ├── kotlin/.../MainActivity.kt  # Overlay + MediaProjection
│   │   ├── res/layout/floating_bubble.xml  # Layout burbuja flotante
│   │   └── AndroidManifest.xml         # Permisos
│   └── build.gradle.kts               # Configuración Android
```

---

## ⚙️ Configuración Avanzada

### Cambiar Idiomas de Traducción

En `lib/services/translation_service.dart`:

```dart
Future<String> translate({
  required String text,
  String sourceLang = 'en',  // Cambiar a 'fr', 'de', etc.
  String targetLang = 'es',  // Cambiar a 'en', 'pt', etc.
})
```

Idiomas soportados por LibreTranslate:
- `en` (Inglés)
- `es` (Español)
- `fr` (Francés)
- `de` (Alemán)
- `pt` (Portugués)
- `it` (Italiano)
- `ja` (Japonés)
- `zh` (Chino)
- `ru` (Ruso)

### Optimizar para Juegos

Para mejorar el rendimiento en juegos:

1. **Reducir frecuencia de OCR:**
```dart
Handler(Looper.getMainLooper()).postDelayed({
  // Captura de pantalla
}, 300)  // Aumentar de 100ms a 300ms
```

2. **Desactivar portapapeles cuando no se use:**
```dart
clipboardService.stopWatching();
```

3. **Usar burbuja pequeña:**
Edita `android/app/src/main/res/layout/floating_bubble.xml`:
```xml
<androidx.cardview.widget.CardView
    android:layout_width="50dp"  <!-- Reducir de 60dp -->
    android:layout_height="50dp"
    ...>
```

---

## 🐛 Solución de Problemas

### ❌ "Permiso de overlay denegado"
**Solución:** Ve a Configuración → Apps → Traductor Flotante → Permisos → Activar "Mostrar sobre otras apps"

### ❌ "Error en traducción"
**Solución:** Verifica tu conexión a Internet. LibreTranslate requiere conexión activa.

### ❌ "No se detectó texto en la imagen"
**Solución:** 
- Asegúrate de que el texto sea legible y esté en inglés
- Aumenta el tamaño de texto en el juego/app
- Mejora la iluminación de la pantalla

### ❌ "Error al capturar pantalla"
**Solución:** 
- Acepta el permiso de captura cuando aparezca el diálogo
- Algunos juegos protegen la pantalla contra capturas (limitación de Android)

### ❌ Errores de compilación
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

---

## 📊 Comparación con Otras Apps

| Característica | Esta App | Google Translate | DeepL | Otras Apps |
|---------------|----------|------------------|-------|------------|
| **Costo** | ✅ **GRATIS** | ❌ API de pago | ❌ API de pago | ❌ Freemium |
| **OCR** | ✅ ML Kit (gratis) | ✅ API (pago) | ❌ No | ⚠️ Limitado |
| **Burbuja Flotante** | ✅ Sí | ❌ No | ❌ No | ⚠️ Raro |
| **Portapapeles** | ✅ Sí | ⚠️ Parcial | ⚠️ Parcial | ✅ Sí |
| **Voz** | ✅ Gratis on-device | ❌ API de pago | ❌ API de pago | ⚠️ Limitado |
| **Sin Anuncios** | ✅ Sí | ⚠️ En versión gratis | ⚠️ Freemium | ❌ Anuncios |

---

## 🎯 Casos de Uso

### 🎮 Juegos en Inglés
- Traducir diálogos, misiones, menús
- Usar la burbuja flotante sin salir del juego
- OCR para texto en pantalla

### 📚 Apps de Lectura
- Traducir artículos, ebooks, PDFs
- Copiar texto y traducir automáticamente

### 💬 Redes Sociales
- Traducir mensajes, publicaciones, comentarios
- Usar portapapeles para traducción rápida

### 🌐 Navegación Web
- Traducir páginas web
- OCR para imágenes con texto

---

## 🔮 Próximas Mejoras (Roadmap)

- [ ] Soporte para más idiomas (FR, DE, PT, etc.)
- [ ] Historial de traducciones
- [ ] Modo offline con traducción básica
- [ ] Widget de Android para acceso rápido
- [ ] Traducción de conversaciones en tiempo real
- [ ] Detección automática de idioma
- [ ] Personalización de la burbuja (color, tamaño)
- [ ] Exportar traducciones a archivo

---

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Si encuentras un bug o tienes una sugerencia:

1. Abre un **Issue**
2. Haz un **Fork** del proyecto
3. Crea una **Pull Request**

---

## 👨‍💻 Autor

Creado con ❤️ para la comunidad hispanohablante que juega y usa apps en inglés.

---

## 🙏 Agradecimientos

- **Google ML Kit** por OCR gratuito
- **LibreTranslate** por API de traducción gratuita
- **Flutter** y la comunidad por los plugins gratuitos
- **Comunidad open-source** por hacer esto posible

---

## 📞 Soporte

Si necesitas ayuda:
- 📧 Email: [tu-email]
- 💬 Discord: [tu-discord]
- 🐦 Twitter: [tu-twitter]

---

**⚡ ¡Disfruta traduciendo sin límites y sin pagar! ⚡**
