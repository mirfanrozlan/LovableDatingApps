package com.example.mobile

import android.media.MediaPlayer
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational

class MainActivity : FlutterActivity() {
    private var mediaPlayer: MediaPlayer? = null
    private val CHANNEL_PIP = "app.pip"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app.ringtone")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        try {
                            playDefaultRingtone()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERR_PLAY", e.message, null)
                        }
                    }
                    "stop" -> {
                        try {
                            stopRingtone()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERR_STOP", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_PIP)
            .setMethodCallHandler { call, result ->
                if (call.method == "enterPip") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val width = call.argument<Int>("width") ?: 16
                        val height = call.argument<Int>("height") ?: 9
                        val params = PictureInPictureParams.Builder()
                            .setAspectRatio(Rational(width, height))
                            .build()
                        enterPictureInPictureMode(params)
                        result.success(true)
                    } else {
                        result.error("NOT_SUPPORTED", "PiP not supported", null)
                    }
                } else if (call.method == "setAutoPip") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val width = call.argument<Int>("width") ?: 16
                        val height = call.argument<Int>("height") ?: 9
                        val params = PictureInPictureParams.Builder()
                            .setAutoEnterEnabled(enabled)
                            .setAspectRatio(Rational(width, height))
                            .build()
                        setPictureInPictureParams(params)
                        result.success(true)
                    } else {
                         result.success(false)
                    }
                } else if (call.method == "closePip") {
                     moveTaskToBack(true)
                     result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
            MethodChannel(messenger, CHANNEL_PIP)
                .invokeMethod("pipModeChanged", mapOf("isInPipMode" to isInPictureInPictureMode))
        }
    }

    private fun playDefaultRingtone() {
        stopRingtone()
        val uri: Uri = Settings.System.DEFAULT_RINGTONE_URI
        mediaPlayer = MediaPlayer.create(this, uri)
        mediaPlayer?.isLooping = true
        mediaPlayer?.setVolume(1.0f, 1.0f)
        mediaPlayer?.start()
    }

    private fun stopRingtone() {
        mediaPlayer?.let {
            try {
                if (it.isPlaying) it.stop()
            } catch (_: Exception) { }
            try {
                it.reset()
            } catch (_: Exception) { }
            try {
                it.release()
            } catch (_: Exception) { }
        }
        mediaPlayer = null
    }
}
