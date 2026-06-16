package com.msicore.rkfm.rkfm_broadcast

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
import kotlin.math.log10

class AudioEnginePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var meterChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var audioRecord: AudioRecord? = null
    private var metering = false
    private var muted = false
    private var gain = 1.0f
    private var inputSource = "builtin"

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.msicore.rkfm/audio")
        channel.setMethodCallHandler(this)
        meterChannel = EventChannel(binding.binaryMessenger, "com.msicore.rkfm/audio_meter")
        meterChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                startMetering()
            }
            override fun onCancel(arguments: Any?) {
                stopMetering()
                eventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopMetering()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> result.success(true)
            "setInputSource" -> {
                inputSource = call.argument<String>("source") ?: "builtin"
                result.success(true)
            }
            "setGain" -> {
                gain = (call.argument<Double>("gain") ?: 1.0).toFloat()
                result.success(true)
            }
            "mute" -> { muted = true; result.success(true) }
            "unmute" -> { muted = false; result.success(true) }
            "setNoiseGate" -> result.success(true)
            "setCompressor" -> result.success(true)
            "setLimiter" -> result.success(true)
            "setEqualizer" -> result.success(true)
            "getStatus" -> result.success(mapOf(
                "inputSource" to inputSource,
                "gain" to gain,
                "muted" to muted,
                "latencyMs" to 45
            ))
            else -> result.notImplemented()
        }
    }

    private fun startMetering() {
        if (metering) return
        metering = true
        Thread {
            val sampleRate = 44100
            val bufferSize = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_STEREO,
                AudioFormat.ENCODING_PCM_16BIT
            )
            try {
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    sampleRate,
                    AudioFormat.CHANNEL_IN_STEREO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferSize
                )
                val buffer = ShortArray(bufferSize / 2)
                audioRecord?.startRecording()
                while (metering) {
                    val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                    if (read > 0) {
                        var leftPeak = 0.0
                        var rightPeak = 0.0
                        for (i in 0 until read step 2) {
                            leftPeak = maxOf(leftPeak, abs(buffer[i].toDouble()))
                            if (i + 1 < read) {
                                rightPeak = maxOf(rightPeak, abs(buffer[i + 1].toDouble()))
                            }
                        }
                        val leftDb = if (leftPeak > 0) 20 * log10(leftPeak / 32768.0) else -60.0
                        val rightDb = if (rightPeak > 0) 20 * log10(rightPeak / 32768.0) else -60.0
                        val level = if (muted) mapOf("left" to -60.0, "right" to -60.0, "peak" to -60.0)
                        else mapOf("left" to leftDb, "right" to rightDb, "peak" to maxOf(leftDb, rightDb))
                        eventSink?.success(level)
                    }
                    Thread.sleep(50)
                }
            } catch (_: Exception) {
            } finally {
                audioRecord?.stop()
                audioRecord?.release()
                audioRecord = null
            }
        }.start()
    }

    private fun stopMetering() {
        metering = false
    }
}
