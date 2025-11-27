package com.example.flutter_app_traducctorpantallas

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
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

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

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
                        if (Math.abs(dx) < 5 && Math.abs(dy) < 5) {
                            // Es un click
                            onBubbleClicked()
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

    // Acción al hacer click en la burbuja
    private fun onBubbleClicked() {
        Toast.makeText(this, "Capturando en 500ms...", Toast.LENGTH_SHORT).show()
        
        // Delay para que la burbuja vuelva a su posición y no capturemos nuestra app
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            requestScreenCapture()
        }, 500) // 500ms de delay
    }

    // Solicitar captura de pantalla
    private fun requestScreenCapture() {
        val captureIntent = mediaProjectionManager?.createScreenCaptureIntent()
        startActivityForResult(captureIntent, REQUEST_CODE_SCREENSHOT)
    }

    // Capturar pantalla usando servicio foreground (Android 14+)
    @Suppress("DEPRECATION")
    private fun captureScreen(resultCode: Int, data: Intent?) {
        // Configurar callback para recibir resultado
        ScreenCaptureService.callback = { filePath ->
            if (filePath != null) {
                // Enviar ruta a Flutter
                methodChannel?.invokeMethod("onScreenCaptured", filePath)
                Toast.makeText(this, "✅ Captura exitosa", Toast.LENGTH_SHORT).show()
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

    override fun onDestroy() {
        super.onDestroy()
        hideFloatingBubble()
        ScreenCaptureService.callback = null
    }
}
