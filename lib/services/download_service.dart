import 'download_service_stub.dart'
    if (dart.library.html) 'download_service_web.dart' as impl;

class DownloadService {
  static Future<bool> download(String url, {String? filename}) {
    final name = filename ?? 'My_Invitation_${DateTime.now().millisecondsSinceEpoch}.mp4';
    return impl.downloadVideoFile(url, name);
  }
}

