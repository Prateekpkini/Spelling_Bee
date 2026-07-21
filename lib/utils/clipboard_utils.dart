import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

Future<void> copyTextRobust(BuildContext context, String text) async {
  bool success = false;
  if (kIsWeb) {
    try {
      final textArea = html.TextAreaElement();
      textArea.value = text;
      textArea.style.position = 'fixed';
      textArea.style.left = '-9999px';
      html.document.body?.append(textArea);
      textArea.focus();
      textArea.select();
      success = html.document.execCommand('copy');
      textArea.remove();
    } catch (_) {}
  }
  
  if (!success) {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      success = true;
    } catch (_) {}
  }

  if (context.mounted) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to copy automatically. Please copy the text manually.', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
