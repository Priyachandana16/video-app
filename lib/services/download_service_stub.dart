import 'dart:io';
import 'package:flutter/services.dart';
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

    // 1. If Flutter asset packaged inside the APK
    if (url.startsWith('assets/')) {
      final byteData = await rootBundle.load(url);
      final buffer = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final targetFile = File(savePath);
      await targetFile.writeAsBytes(buffer);
      if (Platform.isAndroid || Platform.isIOS) {
        await Share.shareXFiles([XFile(savePath)], text: 'My Invitation Video');
      }
      return true;
    }

    // 2. If already a local file path
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

    // 3. Network URL: fetch bytes
    final fullUrl = url.startsWith('http')
        ? url
        : 'https://myinvitation-abun.onrender.com$url';

    final res = await http.get(Uri.parse(fullUrl)).timeout(const Duration(seconds: 45));
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

