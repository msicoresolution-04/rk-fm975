package com.msicore.rkfm.rkfm_broadcast

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var cameraPlugin: CameraXPlugin? = null
    private var recordingPlugin: RecordingPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        cameraPlugin = CameraXPlugin()
        recordingPlugin = RecordingPlugin()
        recordingPlugin?.setCameraPlugin(cameraPlugin!!)
        flutterEngine.plugins.add(cameraPlugin!!)
        flutterEngine.plugins.add(recordingPlugin!!)
        flutterEngine.plugins.add(RtmpStreamPlugin())
        flutterEngine.plugins.add(AudioEnginePlugin())
        flutterEngine.plugins.add(SystemMonitorPlugin())
    }
}
