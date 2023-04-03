package com.example.spothole

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager


class MainActivity: FlutterActivity() {
  private lateinit var cameraMgr: CameraManager
  override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.spothole/camera").setMethodCallHandler {
      call, result ->
        if(call.method == "getFocalLength") {
          val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
          val cameraId = cameraManager.cameraIdList[0] 
          val characteristics = cameraManager.getCameraCharacteristics(cameraId)
          val focalLength = characteristics.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS)?.get(0)
          result.success(focalLength)
        }
        else {
          result.notImplemented()
        }
    }
  }
}