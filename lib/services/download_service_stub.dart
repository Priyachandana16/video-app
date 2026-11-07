import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> downloadVideoFile(String url, String filename) async {
  try {
    Directory? dir;
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (downloadDir.existsSync()) {
        dir = downloadDir;
      } else {
        dir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    } else {
      dir = await getApplicationDocumentsDirectory();
    }

    final savePath = '${dir.path}/$filename';

    // If already a local file path
    if (!url.startsWith('http')) {
      final localFile = File(url);
      if (localFile.existsSync()) {
        await localFile.copy(savePath);
        if (Platform.isAndroid || Platform.isIOS) {
          await Share.shareXFiles([XFile(savePath)], text: 'My Invitation Video');
        }
        return true;
      }
    }

    // Network URL: fetch bytes
    final fullUrl = url.startsWith('http')
        ? url
        : (Platform.isAndroid ? 'http://10.0.2.2:5000$url' : 'http://localhost:5000$url');

    final res = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      final targetFile = File(savePath);
      await targetFile.writeAsBytes(res.bodyBytes);
      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles([XFile(savePath)], text: 'My Invitation Video');
      }
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}

