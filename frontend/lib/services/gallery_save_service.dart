import 'dart:typed_data';

import 'gallery_save_service_stub.dart'
    if (dart.library.io) 'gallery_save_service_io.dart' as impl;
import 'gallery_save_types.dart';

bool get supportsSystemGallerySave => impl.supportsSystemGallerySave;

Future<GallerySaveResult> saveImageToSystemGallery(
  Uint8List bytes, {
  required String filename,
  DateTime? creationDate,
}) {
  return impl.saveImageToSystemGallery(
    bytes,
    filename: filename,
    creationDate: creationDate,
  );
}
