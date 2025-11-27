# 🚀 Guía Rápida de Inicio

## ⚡ Compilar y Ejecutar (3 pasos)

### 1️⃣ Instalar dependencias
```bash
flutter pub get
```

### 2️⃣ Conectar dispositivo Android (o iniciar emulador)
```bash
flutter devices
```

### 3️⃣ Ejecutar la app
```bash
flutter run
```

---

## 📦 Compilar APK para Instalar

### Debug (para pruebas):
```bash
flutter build apk --debug
```

### Release (para distribución):
```bash
flutter build apk --release
```

**APK generado en:**
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## ✅ Verificar Configuración

### Verificar Flutter
```bash
flutter doctor
```

### Verificar dispositivos conectados
```bash
flutter devices
```

### Limpiar proyecto si hay errores
```bash
flutter clean
flutter pub get
flutter build apk
```

---

## 🎯 Uso Básico de la App

1. **Activar Burbuja Flotante** → Aparece círculo azul sobre todas las apps
2. **Tocar la burbuja** → Captura la pantalla y traduce texto
3. **Activar Portapapeles** → Copia texto en inglés desde cualquier app y se traduce solo
4. **Traducir por Voz** → Habla en inglés y escucha la traducción en español

---

## ⚙️ Permisos Necesarios

La app solicitará automáticamente:
- ✅ Mostrar sobre otras apps (burbuja flotante)
- ✅ Acceso al micrófono (voz a texto)
- ✅ Captura de pantalla (OCR)

**Si no funciona:** Ve a Configuración → Apps → Traductor Flotante → Permisos

---

## 🐛 Solución Rápida de Errores

### Error de compilación
```bash
flutter clean
flutter pub get
```

### Error "SDK not found"
```bash
flutter config --android-sdk <ruta-android-sdk>
```

### Error de permisos en Android
- Ve a Configuración del dispositivo
- Apps → Traductor Flotante
- Permisos → Activar todos

---

## 📱 Requisitos Mínimos

- Android 7.0 o superior (API 24+)
- Conexión a Internet (para traducción)
- 50 MB de espacio libre

---

## 🆘 Ayuda Rápida

**App no captura pantalla:**
- Algunos juegos bloquean capturas (limitación de Android)
- Intenta con otras apps primero

**Traducción muy lenta:**
- Verifica tu conexión a Internet
- LibreTranslate API pública puede tener latencia

**Burbuja no aparece:**
- Activa permiso "Mostrar sobre otras apps" manualmente
- Configuración → Apps → Permisos especiales

---

## 🎉 ¡Listo para Usar!

La app es **100% GRATUITA** y no tiene límites de uso.

**Servicios gratuitos usados:**
- ✅ Google ML Kit (OCR)
- ✅ LibreTranslate API (Traducción)
- ✅ Speech-to-Text on-device
- ✅ Flutter TTS

---

**Documentación completa:** Ver `README.md`
