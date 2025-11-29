package com.example.flutter_app_traducctorpantallas

import android.content.Context
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.TextView
import android.os.Handler
import android.os.Looper

/**
 * Overlay que muestra las traducciones de forma semi-transparente
 */
class TranslationOverlayView(private val context: Context) {
    private val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private var overlayView: View? = null
    private val handler = Handler(Looper.getMainLooper())
    private var hideRunnable: Runnable? = null
    
    fun showTranslation(originalText: String, translatedText: String, autoHideDuration: Long = 8000) {
        handler.post {
            try {
                println("🎯 Mostrando overlay de traducción...")
                
                // Remover overlay anterior si existe
                hideOverlay()
                
                // Crear nueva vista
                overlayView = createOverlayView(originalText, translatedText)
                
                // Configurar parámetros de ventana
                val params = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
                    y = 100 // Margen desde abajo
                }
                
                // Añadir vista
                windowManager.addView(overlayView, params)
                println("✅ Overlay añadido al WindowManager")
                
                // Programar auto-hide
                if (autoHideDuration > 0) {
                    hideRunnable = Runnable { hideOverlay() }
                    handler.postDelayed(hideRunnable!!, autoHideDuration)
                }
            } catch (e: Exception) {
                println("❌ Error mostrando overlay: ${e.message}")
                e.printStackTrace()
            }
        }
    }
    
    private fun createOverlayView(originalText: String, translatedText: String): View {
        // Crear layout programáticamente para evitar problemas con recursos
        val container = android.widget.LinearLayout(context).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            setBackgroundColor(0xE6000000.toInt()) // Negro semi-transparente
            setPadding(40, 30, 40, 30)
        }
        
        // Texto original (pequeño, gris)
        val text1 = TextView(context).apply {
            text = "📝 Original: ${originalText.take(100)}${if(originalText.length > 100) "..." else ""}"
            textSize = 12f
            setTextColor(0xFFAAAAAA.toInt())
        }
        
        // Traducción (grande, blanco)
        val text2 = TextView(context).apply {
            text = "🌐 $translatedText"
            textSize = 18f
            setTextColor(0xFFFFFFFF.toInt())
            setPadding(0, 10, 0, 0)
        }
        
        container.addView(text1)
        container.addView(text2)
        
        // Hacer clic para cerrar
        container.setOnClickListener { hideOverlay() }
        
        return container
    }
    
    fun hideOverlay() {
        handler.post {
            overlayView?.let {
                try {
                    windowManager.removeView(it)
                } catch (e: Exception) {
                    // Vista ya removida
                }
                overlayView = null
            }
            hideRunnable?.let { handler.removeCallbacks(it) }
        }
    }
    
    fun isShowing(): Boolean = overlayView != null
}
