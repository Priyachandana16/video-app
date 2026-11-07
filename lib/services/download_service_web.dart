// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<bool> downloadVideoFile(String url, String filename) async {
  try {
    // Resolve absolute URL if relative
    String fullUrl = url;
    if (url.startsWith('/')) {
      fullUrl = '${html.window.location.protocol}//${html.window.location.host}$url';
    }

    final anchor = html.AnchorElement(href: fullUrl)
      ..setAttribute('download', filename)
      ..target = '_blank'
      ..style.display = 'none';

    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    return true;
  } catch (e) {
    html.window.open(url, '_blank');
    return true;
  }
}

