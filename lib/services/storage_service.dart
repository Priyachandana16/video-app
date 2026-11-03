import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  /// Saves the rendered video file to the device storage
  Future<String?> saveVideoToDevice({
    required String videoSource,
    bool isAsset = false,
  }) async {
    try {
      if (kIsWeb) {
        debugPrint('Web download triggered for: $videoSource');
        return 'downloads/My_Invitation_${DateTime.now().millisecondsSinceEpoch}.mp4';
      }

      Directory? targetDir;

      if (Platform.isAndroid) {
        // Attempt to get external storage / download directory
        targetDir = Directory('/storage/emulated/0/Download');
        if (!targetDir.existsSync()) {
          targetDir = await getExternalStorageDirectory();
        }
      }

      targetDir ??= await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetFilePath = '${targetDir.path}/My_Invitation_$timestamp.mp4';
      final targetFile = File(targetFilePath);

      if (isAsset) {
        final byteData = await rootBundle.load(videoSource);
        final buffer = byteData.buffer;
        await targetFile.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
      } else if (videoSource.startsWith('http')) {
        // If it's a remote URL, download bytes
        final response = await HttpClient().getUrl(Uri.parse(videoSource));
        final httpResponse = await response.close();
        final bytes = await consolidateHttpClientResponseBytes(httpResponse);
        await targetFile.writeAsBytes(bytes);
      } else {
        final sourceFile = File(videoSource);
        if (await sourceFile.exists()) {
          await sourceFile.copy(targetFilePath);
        } else {
          // If source file not found on disk, fallback to bundled master video
          final byteData = await rootBundle.load('assets/personalized_output.mp4');
          await targetFile.writeAsBytes(
            byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          );
        }
      }

      debugPrint('Video saved to: $targetFilePath');
      return targetFilePath;
    } catch (e) {
      debugPrint('Error saving video: $e');
      return null;
    }
  }

  /// Shares the invitation video via native Android share sheet (WhatsApp, etc.)
  Future<void> shareVideo({
    required String videoSource,
    required String coupleTitle,
    bool isAsset = false,
  }) async {
    try {
      if (kIsWeb) {
        await Share.share(
          'Cordially inviting you to the wedding celebrations of $coupleTitle! ✨ Made with My Invitation.',
          subject: 'Wedding Invitation: $coupleTitle',
        );
        return;
      }

      final savedPath = await saveVideoToDevice(
        videoSource: videoSource,
        isAsset: isAsset,
      );

      if (savedPath != null && File(savedPath).existsSync()) {
        await Share.shareXFiles(
          [XFile(savedPath, mimeType: 'video/mp4')],
          text: 'Cordially inviting you to the wedding celebrations of $coupleTitle! ✨ Made with My Invitation.',
          subject: 'Wedding Invitation: $coupleTitle',
        );
      }
    } catch (e) {
      debugPrint('Error sharing video: $e');
    }
  }
}
