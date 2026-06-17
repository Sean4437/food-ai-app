import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import 'gallery_save_types.dart';

const bool supportsSystemGallerySave = !kIsWeb;
const String _androidRelativePath = 'Pictures/Food AI';
const PermissionRequestOption _galleryPermission = PermissionRequestOption(
  iosAccessLevel: IosAccessLevel.addOnly,
  androidPermission: AndroidPermission(
    type: RequestType.image,
    mediaLocation: false,
  ),
);

Future<GallerySaveResult> saveImageToSystemGallery(
  Uint8List bytes, {
  required String filename,
  DateTime? creationDate,
}) async {
  if (kIsWeb || (!Platform.isIOS && !Platform.isAndroid)) {
    return const GallerySaveResult(GallerySaveStatus.notSupported);
  }
  final permission = await PhotoManager.requestPermissionExtend(
      requestOption: _galleryPermission);
  if (!permission.hasAccess) {
    return const GallerySaveResult(GallerySaveStatus.permissionDenied);
  }
  try {
    await PhotoManager.editor.saveImage(
      bytes,
      filename: _normalizeFilename(filename),
      relativePath: Platform.isAndroid ? _androidRelativePath : null,
      creationDate: creationDate,
    );
    return const GallerySaveResult(GallerySaveStatus.saved);
  } catch (err) {
    return GallerySaveResult(
      GallerySaveStatus.failed,
      errorMessage: err.toString(),
    );
  }
}

String _normalizeFilename(String filename) {
  final trimmed = filename.trim();
  if (trimmed.isEmpty) {
    return 'food_ai_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
  final lower = trimmed.toLowerCase();
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.heic')) {
    return trimmed;
  }
  return '$trimmed.jpg';
}
