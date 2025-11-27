package com.example.flutter_app_traducctorpantallas

import android.app.*
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.tts.TextToSpeech
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.*

/**
 * Servicio que monitorea el portapapeles en segundo plano
 * y traduce automáticamente texto en inglés
 */
class ClipboardMonitorService : Service() {
    companion object {
        const val NOTIFICATION_ID = 2001
        const val CHANNEL_ID = "clipboard_monitor_channel"
        const val ACTION_START_MONITORING = "start_monitoring"
        const val ACTION_STOP_MONITORING = "stop_monitoring"
        const val EXTRA_AUTO_SPEAK = "auto_speak"
        
        var isRunning = false
        var autoSpeakEnabled = false
    }

    private var clipboardManager: ClipboardManager? = null
    private var lastClipboard = ""
    private val handler = Handler(Looper.getMainLooper())
    private var monitoringRunnable: Runnable? = null
    private var tts: TextToSpeech? = null
    private var ttsInitialized = false

    override fun onCreate() {
        super.onCreate()
        clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        
        // Inicializar TTS
        tts = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale("es", "ES")
                ttsInitialized = true
            }
        }
        
        createNotificationChannel()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_MONITORING -> {
                autoSpeakEnabled = intent.getBooleanExtra(EXTRA_AUTO_SPEAK, false)
                startMonitoring()
            }
            ACTION_STOP_MONITORING -> {
                stopMonitoring()
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Monitor de Portapapeles",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Monitoreando portapapeles para traducción automática"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val stopIntent = Intent(this, ClipboardMonitorService::class.java).apply {
            action = ACTION_STOP_MONITORING
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 0, stopIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationCompat.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            NotificationCompat.Builder(this)
        }

        return builder
            .setContentTitle("📋 Traductor Activo")
            .setContentText("Monitoreando portapapeles...")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Detener", stopPendingIntent)
            .build()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun startMonitoring() {
        if (isRunning) return
        
        isRunning = true
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Monitorear portapapeles cada 2 segundos
        monitoringRunnable = object : Runnable {
            override fun run() {
                checkClipboard()
                handler.postDelayed(this, 2000) // Cada 2 segundos
            }
        }
        handler.post(monitoringRunnable!!)
    }

    private fun stopMonitoring() {
        isRunning = false
        monitoringRunnable?.let { handler.removeCallbacks(it) }
        monitoringRunnable = null
    }

    private fun checkClipboard() {
        try {
            if (!clipboardManager?.hasPrimaryClip()!!) return
            
            val clip = clipboardManager?.primaryClip
            if (clip != null && clip.itemCount > 0) {
                val text = clip.getItemAt(0).text?.toString() ?: return
                
                if (text.isNotEmpty() && text != lastClipboard) {
                    lastClipboard = text
                    
                    // Verificar si es inglés (contiene palabras comunes en inglés)
                    if (isEnglish(text)) {
                        // Traducir en segundo plano
                        translateAndSpeak(text)
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun isEnglish(text: String): Boolean {
        val englishWords = listOf(
            "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
            "have", "has", "had", "do", "does", "did", "will", "would", "should",
            "can", "could", "may", "might", "must", "shall", "to", "of", "in",
            "for", "on", "with", "at", "by", "from", "as", "but", "or", "and",
            "not", "this", "that", "these", "those", "i", "you", "he", "she",
            "it", "we", "they", "what", "which", "who", "when", "where", "why", "how"
        )
        
        val lowerText = text.lowercase()
        val words = lowerText.split(Regex("\\s+"))
        
        // Si al menos 30% de las palabras son palabras comunes en inglés
        val englishCount = words.count { word -> 
            englishWords.any { it == word.trim().replace(Regex("[^a-z]"), "") }
        }
        
        return words.size >= 3 && (englishCount.toFloat() / words.size) >= 0.3
    }

    private fun translateAndSpeak(text: String) {
        // Usar coroutine para no bloquear el thread principal
        CoroutineScope(Dispatchers.IO).launch {
            try {
                // Limpiar texto
                val cleanText = text.trim().substring(0, minOf(text.length, 500))
                
                // Intentar traducir con MyMemory (más confiable para background)
                val translated = translateWithMyMemory(cleanText)
                
                if (translated != null && translated.isNotEmpty()) {
                    // Actualizar notificación con resultado
                    withContext(Dispatchers.Main) {
                        updateNotification("✅ Traducido: ${translated.take(50)}...")
                        
                        // Hablar si está activado
                        if (autoSpeakEnabled && ttsInitialized) {
                            tts?.speak(translated, TextToSpeech.QUEUE_FLUSH, null, null)
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun translateWithMyMemory(text: String): String? {
        return try {
            val encodedText = URLEncoder.encode(text, "UTF-8")
            val url = URL("https://api.mymemory.translated.net/get?q=$encodedText&langpair=en|es")
            
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.connectTimeout = 10000
            connection.readTimeout = 10000
            
            val responseCode = connection.responseCode
            if (responseCode == 200) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                
                // Parsear JSON manualmente (simple)
                val regex = "\"translatedText\":\"([^\"]+)\"".toRegex()
                val match = regex.find(response)
                match?.groupValues?.get(1)?.replace("\\n", "\n")
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun updateNotification(text: String) {
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationCompat.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            NotificationCompat.Builder(this)
        }
            .setContentTitle("📋 Traductor Activo")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        stopMonitoring()
        tts?.stop()
        tts?.shutdown()
    }
}
