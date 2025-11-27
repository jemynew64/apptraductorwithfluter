# 📝 Notas Técnicas Importantes

## ⚠️ Limitaciones Conocidas

### 1. Captura de Pantalla en Juegos
Algunos juegos y apps implementan protección contra capturas de pantalla usando `FLAG_SECURE`. Esto es una **limitación de Android**, no de la app.

**Juegos que pueden bloquear capturas:**
- Netflix, Amazon Prime Video (contenido protegido)
- Algunos juegos bancarios
- Apps con contenido DRM

**Solución:** La app funcionará perfectamente con la mayoría de apps y juegos normales.

---

### 2. API de Traducción Gratuita (LibreTranslate)

**Ventajas:**
- ✅ Completamente gratuita
- ✅ Sin necesidad de API key
- ✅ Sin límites estrictos

**Limitaciones:**
- ⚠️ Puede tener latencia en horas pico (es un servicio público)
- ⚠️ Traducción no tan precisa como Google Translate o DeepL

**Alternativas si LibreTranslate es lenta:**

#### Opción A: MyMemory API (también gratis)
```dart
// En lib/services/translation_service.dart
static const String _baseUrl = 'https://api.mymemory.translated.net/get';

final response = await http.get(
  Uri.parse('$_baseUrl?q=$text&langpair=en|es'),
);
```

#### Opción B: Hostear tu propia instancia de LibreTranslate
```bash
docker run -ti --rm -p 5000:5000 libretranslate/libretranslate
```
Luego cambia la URL en el código a `http://tu-ip:5000/translate`

---

### 3. OCR con Google ML Kit

**Funciona mejor con:**
- ✅ Texto claro y legible
- ✅ Buen contraste (texto negro en fondo blanco)
- ✅ Tamaño de fuente mediano a grande
- ✅ Texto en inglés (configurado para alfabeto latino)

**Puede tener problemas con:**
- ❌ Texto muy pequeño (< 10px)
- ❌ Fonts estilizadas o manuscritas
- ❌ Texto con mucho ruido de fondo
- ❌ Texto en movimiento (animaciones)

**Mejoras posibles:**
```dart
// En lib/services/ocr_service.dart
final TextRecognizer _textRecognizer = TextRecognizer(
  script: TextRecognitionScript.latin,  // Para inglés
  // script: TextRecognitionScript.chinese,  // Para chino
  // script: TextRecognitionScript.japanese,  // Para japonés
  // script: TextRecognitionScript.korean,  // Para coreano
);
```

---

### 4. Rendimiento en Dispositivos Antiguos

**Requisitos recomendados:**
- Android 7.0+ (API 24+)
- 2 GB RAM mínimo
- Procesador quad-core

**Optimizaciones aplicadas:**
- ✅ OCR on-device (no requiere conexión para detección)
- ✅ Speech-to-Text on-device
- ✅ Overlay ligero (solo una vista pequeña)

**Si la app es lenta:**
```kotlin
// En MainActivity.kt, reducir frecuencia de captura
Handler(Looper.getMainLooper()).postDelayed({
    // Captura
}, 500)  // Aumentar de 100ms a 500ms
```

---

## 🔧 Configuraciones Avanzadas

### Cambiar Endpoint de Traducción

Si quieres usar otro servicio de traducción gratuito:

```dart
// lib/services/translation_service.dart
class TranslationService {
  // Opción 1: LibreTranslate (actual)
  static const String _baseUrl = 'https://libretranslate.com/translate';
  
  // Opción 2: MyMemory (alternativa)
  // static const String _baseUrl = 'https://api.mymemory.translated.net/get';
  
  // Opción 3: Tu servidor propio
  // static const String _baseUrl = 'http://tu-servidor.com/translate';
}
```

---

### Personalizar Burbuja Flotante

#### Cambiar color:
```xml
<!-- android/app/src/main/res/layout/floating_bubble.xml -->
<androidx.cardview.widget.CardView
    app:cardBackgroundColor="#FF5722"  <!-- Naranja en vez de azul -->
```

#### Cambiar tamaño:
```xml
<androidx.cardview.widget.CardView
    android:layout_width="80dp"  <!-- Más grande -->
    android:layout_height="80dp"
```

#### Cambiar ícono:
```xml
<ImageView
    android:src="@android:drawable/ic_menu_camera"  <!-- Cambiar ícono -->
```

---

### Agregar Más Idiomas

#### En traducción:
```dart
// lib/screens/home_screen.dart
final translated = await translationService.translate(
  text: cleanedText,
  sourceLang: 'en',  // Origen
  targetLang: 'fr',  // Destino: francés
);
```

#### En voz:
```dart
// lib/services/speech_service.dart
await speechService.startListening(
  onResult: (text) { ... },
  language: 'fr_FR',  // Francés
);

await speechService.speak(text, language: 'fr-FR');
```

---

## 🧪 Testing y Depuración

### Logs importantes:

```dart
// Ver logs de traducción
print('✅ Traducido: $text');

// Ver logs de OCR
print('📸 Texto extraído: $extractedText');

// Ver logs de portapapeles
print('📋 Texto copiado: $clipboardText');
```

### Comandos útiles:

```bash
# Ver logs en tiempo real
flutter logs

# Ver logs con filtro
adb logcat | findstr "flutter"

# Capturar logs a archivo
adb logcat > logs.txt
```

### Debugging en Android Studio:

1. Conecta el dispositivo
2. Run → Debug
3. Coloca breakpoints en `MainActivity.kt` y archivos Dart
4. Usa el debugger para seguir el flujo

---

## 🚀 Optimizaciones de Producción

### 1. Reducir tamaño del APK

```bash
# Generar APK split por arquitectura
flutter build apk --split-per-abi
```

Esto generará:
- `app-armeabi-v7a-release.apk` (32-bit)
- `app-arm64-v8a-release.apk` (64-bit)
- `app-x86_64-release.apk` (emuladores)

Cada APK será ~50% más pequeño.

### 2. Ofuscar código (ProGuard)

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(...)
    }
}
```

### 3. Comprimir imágenes y recursos

Ya está configurado automáticamente en el `build.gradle.kts`.

---

## 📊 Métricas de Rendimiento Esperadas

| Operación | Tiempo Promedio | Notas |
|-----------|----------------|-------|
| **Traducción (LibreTranslate)** | 1-3 segundos | Depende de conexión |
| **OCR (ML Kit)** | 0.5-1.5 segundos | On-device |
| **Speech-to-Text** | Tiempo real | On-device |
| **Text-to-Speech** | Instantáneo | On-device |
| **Captura de pantalla** | 0.1-0.3 segundos | Nativo |

---

## 🔒 Privacidad y Seguridad

### Datos que SE envían a internet:
- ✅ Texto a traducir (a LibreTranslate API)

### Datos que NO se envían:
- ❌ Capturas de pantalla (se procesan localmente)
- ❌ Audio de voz (se procesa on-device)
- ❌ Portapapeles (se procesa localmente)
- ❌ Información personal

### Permisos justificados:
- **SYSTEM_ALERT_WINDOW**: Para burbuja flotante
- **INTERNET**: Solo para traducción API
- **RECORD_AUDIO**: Solo para voz a texto
- **FOREGROUND_SERVICE_MEDIA_PROJECTION**: Solo para captura OCR

---

## 🆕 Actualizaciones Futuras

### Planeadas:
- [ ] Cache de traducciones offline
- [ ] Historial de traducciones
- [ ] Soporte para más idiomas asiáticos
- [ ] Traducción en tiempo real de conversaciones
- [ ] Widget de Android
- [ ] Temas personalizables

### En consideración:
- [ ] Traducción de imágenes desde galería
- [ ] Exportar traducciones a PDF/TXT
- [ ] Sincronización en la nube (opcional)

---

## 📧 Reporte de Bugs

Si encuentras un bug, incluye:
1. Versión de Android
2. Modelo de dispositivo
3. Pasos para reproducir el error
4. Logs de `flutter logs` o `adb logcat`

---

**Última actualización:** 26 de noviembre de 2025
