// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

/// Web implementation: triggers download via anchor element.
Future<void> downloadFile(Uint8List bytes, String fileName, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
