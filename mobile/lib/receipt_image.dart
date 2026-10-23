import 'dart:typed_data';
import 'package:image/image.dart' as img;

Uint8List compressReceiptPhoto(Uint8List bytes) {
  if (bytes.isEmpty || bytes.length > 20 * 1024 * 1024) {
    throw const FormatException('Choose a photo smaller than 20 MiB.');
  }
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Choose a JPEG, PNG, or WebP photo.');
  }
  var photo = img.bakeOrientation(decoded);
  if (photo.width > 1500 || photo.height > 1500) {
    photo = img.copyResize(
      photo,
      width: photo.width >= photo.height ? 1500 : null,
      height: photo.height > photo.width ? 1500 : null,
      interpolation: img.Interpolation.average,
    );
  }
  final clean = img.Image(
    width: photo.width,
    height: photo.height,
    numChannels: 3,
  );
  img.fill(clean, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(clean, photo);
  return Uint8List.fromList(img.encodeJpg(clean, quality: 82));
}
