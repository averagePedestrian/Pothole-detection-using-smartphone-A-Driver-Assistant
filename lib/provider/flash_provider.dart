import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FlashModeProvider with ChangeNotifier {
  FlashMode flashMode = FlashMode.off;

  bool _isCameraInitialized = true;
  bool _isCameraPermissionGranted = true;
  bool _isPermanentlyDenied = false;
  bool _isNotificationPermissionGranted = true;
  bool _isIgnoringBatteryOptimization = true;
  bool _isOverlayPermissionGranted = true;
  bool _isMicPermissionGranted = true;
  bool _isMicPermissionPermanentlyDenied = false;
  bool _isBothCamAndMicPermissionGranted = true;

  bool get isCameraInitialized => _isCameraInitialized;
  bool get isCameraPermissionGranted => _isCameraPermissionGranted;
  bool get isPermanentlyDenied => _isPermanentlyDenied;
  bool get isNotificationPermissionGranted => _isNotificationPermissionGranted;
  bool get isIgnoringBatteryOptimization => _isIgnoringBatteryOptimization;
  bool get isOverlayPermissionGranted => _isOverlayPermissionGranted;
  bool get isMicPermissionGranted => _isMicPermissionGranted;
  bool get isMicPermissionPermanentlyDenied =>
      _isMicPermissionPermanentlyDenied;
 

  void setIsMicPermissionPermanentlyDenied(bool value) {
    if (_isMicPermissionPermanentlyDenied != value) {
      _isMicPermissionPermanentlyDenied = value;
      notifyListeners();
    }
  }

  void setIsMicPermissionGranted(bool value) {
    if (_isMicPermissionGranted != value) {
      _isMicPermissionGranted = value;
      notifyListeners();
    }
  }

  void setIsOverlayPermissionGranted(bool value) {
    if (_isOverlayPermissionGranted != value) {
      _isOverlayPermissionGranted = value;
      notifyListeners();
    }
  }

  void setIsCameraInitialized(bool value) {
    if (_isCameraInitialized != value) {
      _isCameraInitialized = value;
      notifyListeners();
    }
  }

  void setIsCameraPermissionGranted(bool value) {
    if (_isCameraPermissionGranted != value) {
      _isCameraPermissionGranted = value;
      notifyListeners();
    }
  }

  void setIsPermanentlyDenied(bool value) {
    if (_isPermanentlyDenied != value) {
      _isPermanentlyDenied = value;
      notifyListeners();
    }
  }

  void setIsNotificationPermissionGranted(bool value) {
    if (_isNotificationPermissionGranted != value) {
      _isNotificationPermissionGranted = value;
      notifyListeners();
    }
  }

  void setIsIgnoringBatteryOptimizattion(bool value) {
    if (_isIgnoringBatteryOptimization != value) {
      _isIgnoringBatteryOptimization = value;
      notifyListeners();
    }
  }

  void changeFlashModetoTorch() {
    if (flashMode == FlashMode.torch) {
      flashMode = FlashMode.off;
      notifyListeners();
    } else {
      flashMode = FlashMode.torch;
      notifyListeners();
    }
  }

  bool bothCameraAndNotificationGranted() {
    if (_isCameraPermissionGranted && _isNotificationPermissionGranted) {
      notifyListeners();
      return true;
    }
    return false;
  }

  void changeFlashModetoAuto() {
    if (flashMode == FlashMode.auto) {
      flashMode = FlashMode.off;
      notifyListeners();
    } else {
      flashMode = FlashMode.auto;
      notifyListeners();
    }
  }
}
