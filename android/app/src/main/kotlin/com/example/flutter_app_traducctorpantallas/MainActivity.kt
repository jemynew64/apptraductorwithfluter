package com.example.flutter_app_traducctorpantallas

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.BroadcastReceiver
import android.content.IntentFilter
import android.graphics.PixelFormat
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.traductor.flotante/overlay"
    private val REQUEST_CODE_OVERLAY = 1234
    private val REQUEST_CODE_SCREENSHOT = 5678
    
    private var overlayView: View? = null
    private var windowManager: WindowManager? = null
    private var methodChannel: MethodChannel? = null
    
    // MediaProjection para captura de pantalla
    private var mediaProjectionManager: MediaProjectionManager? = null
    
    // Overlay de traducción
    private var translationOverlay: TranslationOverlayView? = null
    
    // Modo Manga
    private var isMangaMode = false
    private var tapCount = 0
    private var lastTapTime = 0L
    private val DOUBLE_TAP_TIME = 600L // 600ms para doble tap
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())
    
    // Broadcast Receiver para scroll detenido
    private val scrollStoppedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (isMangaMode) {
                println("📨 Recibido: Usuario dejó de scrollear - Auto-capturando")
                autoCaptureMangaPage()
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        
        // Registrar receiver para scroll detenido
        val filter = IntentFilter("com.traductor.flotante.SCROLL_STOPPED")
        registerReceiver(scrollStoppedReceiver, filter, RECEIVER_NOT_EXPORTED)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showOverlay" -> {
                    if (checkOverlayPermission()) {
                        showFloatingBubble()
                        result.success(true)
                    } else {
                        requestOverlayPermission()
                        result.error("NO_PERMISSION", "Permiso de overlay requerido", null)
                    }
                }
                "hideOverlay" -> {
                    hideFloatingBubble()
                    result.success(true)
                }
                "captureScreen" -> {
                    requestScreenCapture()
                    result.success(null) // Responderemos después de la captura
                }
                "showTranslation" -> {
                    val originalText = call.argument<String>("originalText") ?: ""
                    val translatedText = call.argument<String>("translatedText") ?: ""
                    showTranslationOverlay(originalText, translatedText)
                    result.success(true)
                }
                "hideTranslation" -> {
                    hideTranslationOverlay()
                    result.success(true)
                }
                "toggleMangaMode" -> {
                    toggleMangaMode()
                    result.success(isMangaMode)
                }
                "isMangaModeActive" -> {
                    result.success(isMangaMode)
                }
                "openScrollServiceSettings" -> {
                    openAccessibilitySettings()
                    result.success(null)
                }
                "isScrollServiceEnabled" -> {
                    result.success(ScrollDetectionService.isRunning)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Verificar permiso de overlay
    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    // Solicitar permiso de overlay
    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, REQUEST_CODE_OVERLAY)
        }
    }

    // Mostrar burbuja flotante
    @SuppressLint("ClickableViewAccessibility", "InflateParams")
    private fun showFloatingBubble() {
        if (overlayView != null) return

        val inflater = getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        overlayView = inflater.inflate(R.layout.floating_bubble, null)

        val params = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT
            )
        } else {
            WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                PixelFormat.TRANSLUCENT
            )
        }

        params.gravity = Gravity.TOP or Gravity.START
        params.x = 100
        params.y = 100

        // Hacer la burbuja movible
        overlayView?.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f

            @SuppressLint("ClickableViewAccessibility")
            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        params.x = initialX + (event.rawX - initialTouchX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager?.updateViewLayout(overlayView, params)
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        val dx = event.rawX - initialTouchX
                        val dy = event.rawY - initialTouchY
                        if (Math.abs(dx) < 10 && Math.abs(dy) < 10) {
                            // Es un tap - detectar doble tap
                            onBubbleTapped()
                        }
                        return true
                    }
                }
                return false
            }
        })

        windowManager?.addView(overlayView, params)
        Toast.makeText(this, "Burbuja flotante activada", Toast.LENGTH_SHORT).show()
    }

    // Ocultar burbuja flotante
    private fun hideFloatingBubble() {
        overlayView?.let {
            windowManager?.removeView(it)
            overlayView = null
            Toast.makeText(this, "Burbuja flotante desactivada", Toast.LENGTH_SHORT).show()
        }
    }

    // Manejo de taps en la burbuja - SOLO DOBLE TAP
    private fun onBubbleTapped() {
        val currentTime = System.currentTimeMillis()
        val timeSinceLastTap = currentTime - lastTapTime
        
        if (timeSinceLastTap < DOUBLE_TAP_TIME) {
            // Segundo tap dentro del tiempo límite = DOBLE TAP
            tapCount = 0 // Reset contador
            handler.removeCallbacksAndMessages(null) // Cancelar timer
            toggleMangaMode() // Toggle Modo Manga
        } else {
            // Primer tap
            tapCount = 1
            lastTapTime = currentTime
            
            // Programar reset del contador
            handler.postDelayed({
                tapCount = 0
            }, DOUBLE_TAP_TIME)
        }
    }
    
    // Toggle Modo Manga
    private fun toggleMangaMode() {
        isMangaMode = !isMangaMode
        ScrollDetectionService.isMangaModeActive = isMangaMode
        
        if (isMangaMode) {
            Toast.makeText(this, "📖 MODO MANGA ACTIVADO\nScrollea para traducir automáticamente", Toast.LENGTH_LONG).show()
            // Cambiar apariencia de la burbuja
            overlayView?.alpha = 0.6f
            overlayView?.scaleX = 0.9f
            overlayView?.scaleY = 0.9f
        } else {
            Toast.makeText(this, "📖 Modo Manga desactivado", Toast.LENGTH_SHORT).show()
            overlayView?.alpha = 1.0f
            overlayView?.scaleX = 1.0f
            overlayView?.scaleY = 1.0f
        }
        
        // Notificar a Flutter
        methodChannel?.invokeMethod("onMangaModeChanged", isMangaMode)
    }
    
    // Auto-captura para Modo Manga
    private fun autoCaptureMangaPage() {
        // Usar datos de captura guardados previamente
        if (ScreenCaptureService.savedResultCode != null && ScreenCaptureService.savedData != null) {
            println("📸 Auto-captura iniciada (Modo Manga)")
            captureScreen(ScreenCaptureService.savedResultCode!!, ScreenCaptureService.savedData)
        } else {
            Toast.makeText(this, "⚠️ Permiso de captura requerido - Toca burbuja 2 veces primero", Toast.LENGTH_LONG).show()
            requestScreenCapture()
        }
    }
    
    // Abrir configuración de accesibilidad
    private fun openAccessibilitySettings() {
        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
        startActivity(intent)
        Toast.makeText(this, "Activa 'Traductor Flotante - Scroll' en la lista", Toast.LENGTH_LONG).show()
    }

    // Solicitar captura de pantalla
    private fun requestScreenCapture() {
        val captureIntent = mediaProjectionManager?.createScreenCaptureIntent()
        startActivityForResult(captureIntent, REQUEST_CODE_SCREENSHOT)
    }
    
    // Capturar pantalla usando servicio foreground (Android 14+)
    @Suppress("DEPRECATION")
    private fun captureScreen(resultCode: Int, data: Intent?) {
        // Guardar credenciales para Modo Manga
        ScreenCaptureService.savedResultCode = resultCode
        ScreenCaptureService.savedData = data
        
        // Configurar callback para recibir resultado
        ScreenCaptureService.callback = { filePath ->
            if (filePath != null) {
                // Enviar ruta a Flutter
                methodChannel?.invokeMethod("onScreenCaptured", filePath)
                if (!isMangaMode) {
                    Toast.makeText(this, "✅ Captura exitosa", Toast.LENGTH_SHORT).show()
                }
            } else {
                Toast.makeText(this, "❌ Error en captura", Toast.LENGTH_SHORT).show()
            }
        }
        
        // Iniciar servicio foreground para captura
        val intent = Intent(this, ScreenCaptureService::class.java).apply {
            action = ScreenCaptureService.ACTION_START_CAPTURE
            putExtra(ScreenCaptureService.EXTRA_RESULT_CODE, resultCode)
            putExtra(ScreenCaptureService.EXTRA_DATA, data)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        when (requestCode) {
            REQUEST_CODE_OVERLAY -> {
                if (checkOverlayPermission()) {
                    showFloatingBubble()
                } else {
                    Toast.makeText(this, "Permiso de overlay denegado", Toast.LENGTH_SHORT).show()
                }
            }
            REQUEST_CODE_SCREENSHOT -> {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    captureScreen(resultCode, data)
                } else {
                    Toast.makeText(this, "Permiso de captura denegado", Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    // Mostrar overlay de traducción
    private fun showTranslationOverlay(originalText: String, translatedText: String) {
        if (translationOverlay == null) {
            translationOverlay = TranslationOverlayView(this)
        }
        translationOverlay?.showTranslation(originalText, translatedText)
    }
    
    // Ocultar overlay de traducción
    private fun hideTranslationOverlay() {
        translationOverlay?.hideOverlay()
    }

    override fun onDestroy() {
        super.onDestroy()
        hideFloatingBubble()
        hideTranslationOverlay()
        ScreenCaptureService.callback = null
    }
}
