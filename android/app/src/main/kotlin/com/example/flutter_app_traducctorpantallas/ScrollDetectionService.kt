package com.example.flutter_app_traducctorpantallas

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.accessibilityservice.AccessibilityServiceInfo
import android.os.Handler
import android.os.Looper
import android.content.Intent

class ScrollDetectionService : AccessibilityService() {

    private val handler = Handler(Looper.getMainLooper())
    private var scrollStopRunnable: Runnable? = null
    private var lastScrollTime = 0L
    private val SCROLL_STOP_DELAY = 800L // Espera 800ms después del último scroll
    
    companion object {
        var isRunning = false
        var isMangaModeActive = false
        private var instance: ScrollDetectionService? = null
        
        fun getMangaModeStatus(): Boolean {
            return isMangaModeActive
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isRunning = true
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_VIEW_SCROLLED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 100
        }
        serviceInfo = info
        
        println("📜 ScrollDetectionService conectado - Listo para modo manga")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isMangaModeActive || event == null) return
        
        when (event.eventType) {
            AccessibilityEvent.TYPE_VIEW_SCROLLED -> {
                lastScrollTime = System.currentTimeMillis()
                
                // Cancelar timer anterior si existe
                scrollStopRunnable?.let { handler.removeCallbacks(it) }
                
                // Crear nuevo timer
                scrollStopRunnable = Runnable {
                    val timeSinceScroll = System.currentTimeMillis() - lastScrollTime
                    if (timeSinceScroll >= SCROLL_STOP_DELAY) {
                        println("🛑 Usuario dejó de scrollear - Enviando señal de captura")
                        sendScrollStoppedSignal()
                    }
                }
                
                handler.postDelayed(scrollStopRunnable!!, SCROLL_STOP_DELAY)
            }
        }
    }

    private fun sendScrollStoppedSignal() {
        // Enviar broadcast para que MainActivity capture la pantalla
        val intent = Intent("com.traductor.flotante.SCROLL_STOPPED")
        sendBroadcast(intent)
        println("📡 Broadcast enviado: Scroll detenido")
    }

    override fun onInterrupt() {
        println("⚠️ ScrollDetectionService interrumpido")
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        isMangaModeActive = false
        instance = null
        scrollStopRunnable?.let { handler.removeCallbacks(it) }
        println("🛑 ScrollDetectionService destruido")
    }
}
