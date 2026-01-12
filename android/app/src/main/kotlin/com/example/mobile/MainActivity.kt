package com.example.mobile

import android.media.MediaPlayer
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var mediaPlayer: MediaPlayer? = null

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
