import 'dart:typed_data';

/// Stub implementation – should never be called at runtime.
/// Exists only so that conditional imports resolve at compile time.
Future<void> downloadFile(Uint8List bytes, String fileName, String mimeType) {
  throw UnsupportedError('Cannot download files on this platform');
}
