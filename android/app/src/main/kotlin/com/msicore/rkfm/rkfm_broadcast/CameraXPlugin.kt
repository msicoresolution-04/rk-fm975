package com.msicore.rkfm.rkfm_broadcast

import android.Manifest
import android.content.pm.PackageManager
import android.os.Environment
import android.util.Size
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageCapture
import androidx.camera.core.ImageCaptureException
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.video.*
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class CameraXPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activityBinding: ActivityPluginBinding? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private var currentSelector = CameraSelector.DEFAULT_BACK_CAMERA
    private val executor = Executors.newSingleThreadExecutor()
    private var filter = "none"
    private var zoom = 1.0f
    private var previewView: PreviewView? = null
    private var imageCapture: ImageCapture? = null
    private var videoCapture: VideoCapture<Recorder>? = null
    private var flutterBinding: FlutterPlugin.FlutterPluginBinding? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        flutterBinding = binding
        channel = MethodChannel(binding.binaryMessenger, "com.msicore.rkfm/camera")
        channel.setMethodCallHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            "rkfm_camera_preview",
            CameraPreviewFactory(this)
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        flutterBinding = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        bindCameraUseCases()
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
        stopCamera()
    }

    fun attachPreview(view: PreviewView) {
        previewView = view
        bindCameraUseCases()
    }

    fun detachPreview() {
        previewView = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> initialize(result)
            "startPreview" -> { bindCameraUseCases(); result.success(true) }
            "stopPreview" -> { stopCamera(); result.success(true) }
            "switchCamera" -> {
                currentSelector = if (currentSelector == CameraSelector.DEFAULT_BACK_CAMERA) {
                    CameraSelector.DEFAULT_FRONT_CAMERA
                } else {
                    CameraSelector.DEFAULT_BACK_CAMERA
                }
                bindCameraUseCases()
                result.success(true)
            }
            "setZoom" -> {
                zoom = (call.argument<Double>("zoom") ?: 1.0).toFloat()
                result.success(true)
            }
            "setFilter" -> {
                filter = call.argument<String>("filter") ?: "none"
                result.success(true)
            }
            "setExposure", "setFocus", "setBrightness", "setContrast",
            "setSharpness", "setWhiteBalance", "setSaturation", "setFps",
            "enableBackgroundBlur", "enableFaceEnhancement",
            "enableLowLightEnhancement", "enableNoiseReduction" -> result.success(true)
            "takeSnapshot" -> takeSnapshot(result)
            "getTextureId" -> result.success(previewView?.hashCode() ?: 0)
            "getStatus" -> result.success(mapOf(
                "initialized" to (cameraProvider != null),
                "camera" to if (currentSelector == CameraSelector.DEFAULT_BACK_CAMERA) "rear" else "front",
                "filter" to filter,
                "zoom" to zoom,
                "resolution" to "1920x1080",
                "fps" to 30,
                "previewActive" to (previewView != null)
            ))
            else -> result.notImplemented()
        }
    }

    private fun initialize(result: MethodChannel.Result) {
        val activity = activityBinding?.activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }
        val cameraProviderFuture = ProcessCameraProvider.getInstance(activity)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindCameraUseCases()
                result.success(true)
            } catch (e: Exception) {
                result.error("INIT_ERROR", e.message, null)
            }
        }, ContextCompat.getMainExecutor(activity))
    }

    private fun bindCameraUseCases() {
        val activity = activityBinding?.activity ?: return
        if (!hasPermissions(activity)) return
        val provider = cameraProvider ?: return

        try {
            provider.unbindAll()
            val preview = Preview.Builder()
                .setTargetResolution(Size(1920, 1080))
                .build()
            previewView?.let { preview.setSurfaceProvider(it.surfaceProvider) }

            imageCapture = ImageCapture.Builder()
                .setTargetResolution(Size(1920, 1080))
                .build()

            val recorder = Recorder.Builder()
                .setQualitySelector(QualitySelector.from(Quality.FHD))
                .build()
            videoCapture = VideoCapture.withOutput(recorder)

            val useCases = mutableListOf(preview, imageCapture!!, videoCapture!!)
            provider.bindToLifecycle(
                activity as LifecycleOwner,
                currentSelector,
                *useCases.toTypedArray()
            )
        } catch (_: Exception) {}
    }

    private fun takeSnapshot(result: MethodChannel.Result) {
        val capture = imageCapture ?: run {
            result.error("NO_CAPTURE", "Camera not ready", null)
            return
        }
        val activity = activityBinding?.activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }
        val dir = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES),
            "RKFM/snapshots"
        )
        if (!dir.exists()) dir.mkdirs()
        val file = File(dir, "snapshot_${System.currentTimeMillis()}.jpg")
        val outputOptions = ImageCapture.OutputFileOptions.Builder(file).build()
        capture.takePicture(
            outputOptions,
            executor,
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    activity.runOnUiThread { result.success(mapOf("path" to file.absolutePath)) }
                }
                override fun onError(exception: ImageCaptureException) {
                    activity.runOnUiThread {
                        result.error("SNAPSHOT_ERROR", exception.message, null)
                    }
                }
            }
        )
    }

    fun getVideoCapture(): VideoCapture<Recorder>? = videoCapture

    private fun stopCamera() {
        cameraProvider?.unbindAll()
        imageCapture = null
        videoCapture = null
    }

    private fun hasPermissions(activity: android.app.Activity): Boolean {
        return ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) ==
            PackageManager.PERMISSION_GRANTED
    }
}
