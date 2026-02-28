// lib/services/permission_service.dart

import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Demander les permissions nécessaires
  static Future<bool> requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    final mediaLibraryStatus = await Permission.mediaLibrary.request();

    bool cameraGranted = cameraStatus.isGranted;
    bool storageGranted = storageStatus.isGranted;
    bool mediaGranted = mediaLibraryStatus.isGranted;

    return cameraGranted && (storageGranted || mediaGranted);
  }

  /// Vérifier la permission caméra
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Vérifier la permission stockage
  static Future<bool> hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// Ouvrir les paramètres d'application
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}