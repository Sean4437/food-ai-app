import 'dart:typed_data';

import 'gallery_save_types.dart';

const bool supportsSystemGallerySave = false;

Future<GallerySaveResult> saveImageToSystemGallery(
  Uint8List bytes, {
  required String filename,
  DateTime? creationDate,
}) async {
  return const GallerySaveResult(GallerySaveStatus.notSupported);
}
