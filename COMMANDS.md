# 🎯 Comandos Útiles - Traductor Flotante

## 📦 Instalación y Configuración

```bash
# Instalar dependencias
flutter pub get

# Verificar configuración de Flutter
flutter doctor

# Ver dispositivos conectados
flutter devices

# Limpiar proyecto
flutter clean
```

---

## 🚀 Compilación y Ejecución

### Ejecutar en modo desarrollo
```bash
# Ejecutar en dispositivo conectado
flutter run

# Ejecutar en dispositivo específico
flutter run -d <device-id>

# Ejecutar con hot reload habilitado (por defecto)
flutter run --hot
```

### Compilar APK

```bash
# APK Debug (para pruebas)
flutter build apk --debug

# APK Release (para distribución)
flutter build apk --release

# APK Split por arquitectura (más pequeño)
flutter build apk --split-per-abi

# APK con análisis de tamaño
flutter build apk --analyze-size
```

### Compilar App Bundle (para Google Play)
```bash
flutter build appbundle --release
```

---

## 🔍 Debugging y Logs

```bash
# Ver logs en tiempo real
flutter logs

# Ver logs detallados
flutter logs --verbose

# Ver logs de Android (ADB)
adb logcat

# Ver logs filtrados por etiqueta
adb logcat | findstr "flutter"

# Guardar logs en archivo
adb logcat > logs.txt

# Limpiar logs
adb logcat -c
```

---

## 📱 Gestión de Dispositivos

```bash
# Listar dispositivos Android
adb devices

# Instalar APK manualmente
adb install build/app/outputs/flutter-apk/app-release.apk

# Desinstalar app
adb uninstall com.traductor.flotante

# Reiniciar ADB
adb kill-server
adb start-server

# Ver información del dispositivo
adb shell getprop ro.build.version.release  # Versión de Android
adb shell getprop ro.product.model  # Modelo del dispositivo
```

---

## 🧪 Testing

```bash
# Ejecutar tests
flutter test

# Ejecutar tests con cobertura
flutter test --coverage

# Ejecutar tests de integración
flutter drive --target=test_driver/app.dart
```

---

## 🔧 Análisis de Código

```bash
# Analizar código
flutter analyze

# Formatear código automáticamente
dart format lib/

# Verificar dependencias desactualizadas
flutter pub outdated

# Actualizar dependencias
flutter pub upgrade
```

---

## 📊 Performance y Tamaño

```bash
# Analizar tamaño del APK
flutter build apk --analyze-size

# Ver árbol de dependencias
flutter pub deps

# Ver estadísticas de compilación
flutter build apk --verbose

# Profile mode (para análisis de rendimiento)
flutter run --profile
```

---

## 🛠️ Mantenimiento

```bash
# Limpiar cache de Flutter
flutter clean

# Limpiar cache de Gradle (Android)
cd android
./gradlew clean
cd ..

# Actualizar Flutter
flutter upgrade

# Cambiar canal de Flutter (stable/beta/dev)
flutter channel stable
flutter upgrade

# Reparar Flutter si hay problemas
flutter doctor --verbose
flutter pub cache repair
```

---

## 🏗️ Build Android Específico

```bash
# Compilar solo Android (sin Flutter)
cd android
./gradlew assembleRelease
cd ..

# Limpiar build de Android
cd android
./gradlew clean
cd ..

# Ver tareas disponibles de Gradle
cd android
./gradlew tasks
cd ..
```

---

## 📲 Instalación Directa

```bash
# Instalar y ejecutar en un solo comando
flutter install

# Instalar APK específico
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Instalar y sobrescribir si existe
adb install -r -d build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔑 Permisos (Debug)

```bash
# Ver permisos de la app instalada
adb shell dumpsys package com.traductor.flotante | findstr "permission"

# Otorgar permiso de overlay manualmente
adb shell appops set com.traductor.flotante SYSTEM_ALERT_WINDOW allow

# Otorgar permiso de micrófono
adb shell pm grant com.traductor.flotante android.permission.RECORD_AUDIO
```

---

## 🖼️ Captura de Pantalla y Video (desde PC)

```bash
# Captura de pantalla del dispositivo
adb shell screencap /sdcard/screen.png
adb pull /sdcard/screen.png

# Grabar video de la pantalla (30 segundos)
adb shell screenrecord /sdcard/demo.mp4
# Presiona Ctrl+C para detener antes de 30s
adb pull /sdcard/demo.mp4
```

---

## 📦 Gestión de Assets y Recursos

```bash
# Regenerar código generado (si usas build_runner)
flutter pub run build_runner build --delete-conflicting-outputs

# Listar assets incluidos en el APK
unzip -l build/app/outputs/flutter-apk/app-release.apk
```

---

## 🌐 Traducción y Localización (Futuro)

```bash
# Si agregas soporte para múltiples idiomas:
flutter pub run intl_utils:generate
```

---

## 🐛 Solución Rápida de Problemas

### Problema: "SDK not found"
```bash
# Windows
flutter config --android-sdk C:\Users\TU_USUARIO\AppData\Local\Android\Sdk

# Verificar
flutter doctor
```

### Problema: "Gradle error"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Problema: "Plugin not found"
```bash
flutter clean
rm pubspec.lock
flutter pub get
```

### Problema: "Build failed"
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build apk
```

---

## 📈 Workflow Recomendado

### Desarrollo diario:
```bash
1. flutter run  # Ejecutar con hot reload
2. # Hacer cambios en el código
3. # Presiona 'r' en consola para hot reload
4. # Presiona 'R' para hot restart
5. # Presiona 'q' para salir
```

### Antes de compilar release:
```bash
1. flutter analyze  # Verificar errores
2. dart format lib/  # Formatear código
3. flutter test  # Ejecutar tests
4. flutter build apk --release  # Compilar
```

---

## 🎁 Extras

### Ver información de compilación
```bash
flutter --version
flutter doctor -v
```

### Generar ícono de la app (si usas flutter_launcher_icons)
```bash
flutter pub run flutter_launcher_icons:main
```

### Abrir emulador de Android
```bash
# Listar emuladores disponibles
emulator -list-avds

# Iniciar emulador específico
emulator -avd <nombre_emulador>
```

---

## 📝 Notas Finales

- Usa `flutter run` durante desarrollo (hot reload es tu amigo)
- Usa `flutter build apk --release` para distribución
- Usa `flutter build apk --split-per-abi` para reducir tamaño
- Siempre ejecuta `flutter clean` si tienes problemas extraños
- Mantén Flutter actualizado: `flutter upgrade`

---

**Comandos más usados en orden:**
1. `flutter pub get` - Después de clonar
2. `flutter run` - Durante desarrollo
3. `flutter build apk --release` - Para compartir app
4. `flutter clean` - Cuando algo falla
5. `flutter doctor` - Para verificar todo está bien

---

**¡Happy coding! 🚀**
