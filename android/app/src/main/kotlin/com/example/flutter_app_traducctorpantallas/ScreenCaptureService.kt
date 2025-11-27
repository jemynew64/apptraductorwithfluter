package com.example.flutter_app_traducctorpantallas

import android.app.*
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import java.io.File
import java.io.FileOutputStream
import java.nio.ByteBuffer

/**
 * Servicio foreground requerido para MediaProjection en Android 14+
 */
class ScreenCaptureService : Service() {
    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "screen_capture_channel"
        const val ACTION_START_CAPTURE = "start_capture"
        const val ACTION_STOP_CAPTURE = "stop_capture"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_DATA = "data"
        
        var callback: ((String?) -> Unit)? = null
    }

    private var mediaProjection: MediaProjection? = null
    private var imageReader: ImageReader? = null
    private var virtualDisplay: VirtualDisplay? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_CAPTURE -> {
                val resultCode = intent.getIntExtra(EXTRA_RESULT_CODE, Activity.RESULT_CANCELED)
                val data = intent.getParcelableExtra<Intent>(EXTRA_DATA)
                
                // Iniciar servicio foreground con notificación
                val notification = createNotification()
                startForeground(NOTIFICATION_ID, notification, 
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
                
                // Capturar pantalla
                captureScreen(resultCode, data)
            }
            ACTION_STOP_CAPTURE -> {
                stopCapture()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Captura de Pantalla",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Capturando pantalla para traducción"
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationCompat.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            NotificationCompat.Builder(this)
        }

        return builder
            .setContentTitle("Traductor Flotante")
            .setContentText("Capturando pantalla...")
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }

    @Suppress("DEPRECATION")
    private fun captureScreen(resultCode: Int, data: Intent?) {
        if (data == null) {
            callback?.invoke(null)
            stopSelf()
            return
        }

        val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)

        val metrics = resources.displayMetrics
        val density = metrics.densityDpi
        val width = metrics.widthPixels
        val height = metrics.heightPixels

        imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface, null, null
        )

        Handler(Looper.getMainLooper()).postDelayed({
            try {
                val image: Image? = imageReader?.acquireLatestImage()
                if (image != null) {
                    val bitmap = imageToBitmap(image, width, height)
                    image.close()
                    
                    // Guardar bitmap
                    val file = saveBitmap(bitmap)
                    
                    // Enviar ruta a través del callback
                    callback?.invoke(file?.absolutePath)
                } else {
                    callback?.invoke(null)
                }
            } catch (e: Exception) {
                e.printStackTrace()
                callback?.invoke(null)
            } finally {
                stopCapture()
                stopSelf()
            }
        }, 300)
    }

    private fun imageToBitmap(image: Image, width: Int, height: Int): Bitmap {
        val planes = image.planes
        val buffer: ByteBuffer = planes[0].buffer
        val pixelStride = planes[0].pixelStride
        val rowStride = planes[0].rowStride
        val rowPadding = rowStride - pixelStride * width

        val bitmap = Bitmap.createBitmap(
            width + rowPadding / pixelStride,
            height,
            Bitmap.Config.ARGB_8888
        )
        bitmap.copyPixelsFromBuffer(buffer)
        return bitmap
    }

    private fun saveBitmap(bitmap: Bitmap): File? {
        return try {
            val file = File(cacheDir, "screenshot_${System.currentTimeMillis()}.png")
            val outputStream = FileOutputStream(file)
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
            outputStream.flush()
            outputStream.close()
            file
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun stopCapture() {
        virtualDisplay?.release()
        mediaProjection?.stop()
        imageReader?.close()
        
        virtualDisplay = null
        mediaProjection = null
        imageReader = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        stopCapture()
    }
}
