import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/session.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';

import '../models/personalization_data.dart';
import '../models/template_model.dart';

/// High-performance On-Device Native FFmpeg Video Invitation Renderer
/// Executes 100% on mobile hardware (Snapdragon/MediaTek) with ZERO cloud server dependency.
class OnDeviceRenderService {
  static final OnDeviceRenderService instance = OnDeviceRenderService._internal();
  OnDeviceRenderService._internal();

  /// Resolve and cache master background video to local file storage
  Future<String> _resolveMasterVideo(TemplateModel template, {void Function(double, String)? onProgress}) async {
    final tempDir = await getTemporaryDirectory();
    final masterRel = template.masterVideoPath.isNotEmpty
        ? template.masterVideoPath
        : ((template.videoUrl != null && template.videoUrl!.isNotEmpty)
            ? template.videoUrl!
            : 'assets/templates/template_01_green_screen.mp4');

    // Case 1: Remote HTTP/HTTPS video URL
    if (masterRel.startsWith('http://') || masterRel.startsWith('https://')) {
      final cacheName = 'master_${template.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}.mp4';
      final cacheFile = File('${tempDir.path}/$cacheName');
      if (await cacheFile.exists() && (await cacheFile.length()) > 500000) {
        return cacheFile.path;
      }

      onProgress?.call(0.08, 'Downloading template video to device...');
      final response = await http.get(Uri.parse(masterRel));
      if (response.statusCode == 200) {
        await cacheFile.writeAsBytes(response.bodyBytes);
        return cacheFile.path;
      }
      throw Exception('Failed to download master template video (${response.statusCode})');
    }

    // Case 2: Bundled Flutter asset (assets/templates/...)
    final assetKey = masterRel.replaceFirst(RegExp(r'^\/'), '');
    final cacheName = 'asset_${template.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}.mp4';
    final cacheFile = File('${tempDir.path}/$cacheName');

    if (!await cacheFile.exists() || (await cacheFile.length()) < 100000) {
      onProgress?.call(0.08, 'Extracting template video to device storage...');
      try {
        final byteData = await rootBundle.load(assetKey);
        await cacheFile.writeAsBytes(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
      } catch (assetErr) {
        // Fallback to sample result or default green screen
        debugPrint('[OnDeviceRender] Asset load fallback: $assetErr');
        final byteData = await rootBundle.load('assets/templates/template_01_green_screen.mp4');
        await cacheFile.writeAsBytes(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        );
      }
    }

    return cacheFile.path;
  }

  /// Render styled typography text to transparent PNG using Flutter Canvas
  /// Natively supports Telugu, Hindi, English, all Unicode wedding glyphs, and rotation
  Future<File> _renderTextToPng({
    required String text,
    required String fontFamily,
    required double fontSize,
    required Color color,
    required TextAlign align,
    required double maxWidth,
    required String outputPath,
    double rotation = 0.0,
  }) async {
    TextStyle style;
    try {
      style = GoogleFonts.getFont(
        fontFamily,
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2)),
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
        ],
      );
    } catch (_) {
      // Fallback for Telugu or system font
      style = TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.bold,
        shadows: const [
          Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 2)),
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
        ],
      );
    }

    final span = TextSpan(text: text, style: style);
    final painter = TextPainter(
      text: span,
      textAlign: align,
      textDirection: TextDirection.ltr,
    );

    painter.layout(maxWidth: maxWidth);

    final tw = painter.width + 16.0;
    final th = painter.height + 16.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    double bw = tw;
    double bh = th;

    if (rotation != 0.0) {
      final rad = rotation * math.pi / 180.0;
      bw = (tw * math.cos(rad).abs() + th * math.sin(rad).abs()).ceilToDouble() + 16.0;
      bh = (tw * math.sin(rad).abs() + th * math.cos(rad).abs()).ceilToDouble() + 16.0;

      canvas.save();
      canvas.translate(bw / 2, bh / 2);
      canvas.rotate(rad);
      painter.paint(canvas, Offset(-tw / 2 + 8, -th / 2 + 8));
      canvas.restore();
    } else {
      painter.paint(canvas, const Offset(8, 8));
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(bw.toInt(), bh.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File(outputPath);
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  /// Main On-Device Render Execution
  Future<Map<String, dynamic>> renderOnDevice(
    PersonalizationData data, {
    TemplateModel? template,
    void Function(double progress, String step)? onProgress,
  }) async {
    try {
      onProgress?.call(0.02, 'Initializing hardware video engine...');
      final tempDir = await getTemporaryDirectory();
      final appDocsDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final jobDir = Directory('${tempDir.path}/render_$timestamp');
      await jobDir.create(recursive: true);

      // Resolve template definition
      TemplateModel activeTemplate = template ??
          TemplateModel(
            id: data.templateId.isNotEmpty ? data.templateId : 'tmpl_telugu_chroma_01',
            title: 'Telugu Vivaham Mandapam',
            category: 'Wedding',
            religion: 'Hindu',
            orientation: '16:9',
            hasPhoto: data.hasPhoto,
            photoSlotsCount: 5,
            durationSeconds: 102,
            badgeText: 'CHROMA KEY PRO',
            description: 'Traditional Telugu Vivaham',
            masterVideoPath: 'assets/templates/template_01_green_screen.mp4',
            thumbnailUrl: '',
          );
      final double duration = activeTemplate.durationSeconds.toDouble();

      // Resolve master video
      final masterVideoPath = await _resolveMasterVideo(activeTemplate, onProgress: onProgress);

      final origCanvasW = activeTemplate.canvasWidth > 0 ? activeTemplate.canvasWidth : 1920;
      final origCanvasH = activeTemplate.canvasHeight > 0 ? activeTemplate.canvasHeight : 1080;
      // 720p HD resolution provides lightning fast 60fps encoding on mobile hardware
      final canvasW = origCanvasW > 1280 ? 1280 : origCanvasW;
      final canvasH = (origCanvasH * (canvasW / origCanvasW)).round();
      final double scaleFactor = canvasW / origCanvasW.toDouble();

      final List<String> inputs = ['-thread_queue_size', '16', '-i', masterVideoPath];
      final List<String> filterChains = [];

      filterChains.add(
        '[0:v]scale=$canvasW:$canvasH:force_original_aspect_ratio=decrease,pad=$canvasW:$canvasH:(ow-iw)/2:(oh-ih)/2,setsar=1[v_canvas]',
      );
      String currentStream = 'v_canvas';
      int inputIdx = 1;

      // 1. Process Uploaded Photos (Multi-Photo Slots)
      if (data.hasPhoto && activeTemplate.imageElements.isNotEmpty) {
        onProgress?.call(0.12, 'Composing wedding photos...');
        for (int i = 0; i < activeTemplate.imageElements.length; i++) {
          final imgEl = activeTemplate.imageElements[i];
          final fieldName = imgEl.field.isNotEmpty ? imgEl.field : 'photo_${i + 1}';
          final st = imgEl.startTime;
          final et = imgEl.endTime > 0 ? imgEl.endTime : duration;
          final dur = (et - st).clamp(0.5, duration);
          final animDur = imgEl.animationDuration.clamp(0.3, dur);
          const fadeOut = 0.5;

          final x = (imgEl.x * scaleFactor).round();
          final y = (imgEl.y * scaleFactor).round();
          final w = (imgEl.width * scaleFactor).round().clamp(16, canvasW);
          final h = (imgEl.height * scaleFactor).round().clamp(16, canvasH);

          // Find picked photo path on device
          String? photoPath = data.getSlotPhotoPath(fieldName);
          if (photoPath == null || !File(photoPath).existsSync()) {
            photoPath = data.primaryPhotoPath;
          }

          // If no photo picked for this slot, use candidate logo fallback from assets
          if (photoPath == null || !File(photoPath).existsSync()) {
            final fallbackFile = File('${jobDir.path}/fallback_$i.png');
            try {
              final byteData = await rootBundle.load('assets/candidate_logo1.png');
              await fallbackFile.writeAsBytes(
                byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
              );
              photoPath = fallbackFile.path;
            } catch (_) {}
          }

          if (photoPath != null && File(photoPath).existsSync()) {
            inputs.addAll(['-thread_queue_size', '16', '-loop', '1', '-t', dur.toStringAsFixed(2), '-i', photoPath]);
            final photoInputId = inputIdx++;
            final nextStream = 'v_img_$i';

            String imgFilters = 'scale=$w:$h:force_original_aspect_ratio=increase,crop=$w:$h';

            if (imgEl.chromaKey) {
              final hex = imgEl.chromaKeyColor.replaceAll('#', '').toLowerCase();
              if (hex.length == 6) {
                imgFilters += ',colorkey=0x$hex:0.3:0.1';
              }
            }

            if (imgEl.rotation != 0.0) {
              final rad = (imgEl.rotation * math.pi / 180.0).toStringAsFixed(4);
              imgFilters += ',rotate=$rad:c=none:ow=hypot(iw\\,ih):oh=ow';
            }

            imgFilters += ',format=rgba,fade=t=in:st=0:d=${animDur.toStringAsFixed(2)}:alpha=1,fade=t=out:st=${(dur - fadeOut).clamp(0, dur).toStringAsFixed(2)}:d=${fadeOut.toStringAsFixed(2)}:alpha=1,setpts=PTS-STARTPTS+${st.toStringAsFixed(2)}/TB';

            filterChains.add(
              '[$photoInputId:v]$imgFilters[img_timed_$i]',
            );
            filterChains.add(
              '[$currentStream][img_timed_$i]overlay=$x:$y:enable=\'between(t,${st.toStringAsFixed(2)},${et.toStringAsFixed(2)})\'[$nextStream]',
            );
            currentStream = nextStream;
          }
        }
      }

      // 2. Process Dynamic Typography Overlays (Telugu & English)
      onProgress?.call(0.25, 'Rendering sacred typography & titles...');
      final userFields = data.toFormFields();

      for (int i = 0; i < activeTemplate.textElements.length; i++) {
        final txtEl = activeTemplate.textElements[i];
        final fieldKey = txtEl.field;
        String textVal = userFields[fieldKey] ?? txtEl.defaultText;
        if (textVal.isEmpty && fieldKey == 'coupleNames') {
          textVal = data.coupleTitle;
        }
        if (textVal.isEmpty) continue;

        final st = txtEl.startTime;
        final et = txtEl.endTime > 0 ? txtEl.endTime : duration;
        final dur = (et - st).clamp(0.5, duration);
        final fi = txtEl.fadeIn.clamp(0.1, 3.0);
        final fo = txtEl.fadeOut.clamp(0.1, 3.0);

        final cx = (txtEl.x * scaleFactor).round();
        final cy = (txtEl.y * scaleFactor).round();
        final fontSize = (txtEl.fontSize * scaleFactor).round().clamp(14, 80).toDouble();

        Color fontColor = const Color(0xFFFFD700);
        if (txtEl.fontColor.isNotEmpty) {
          try {
            final hex = txtEl.fontColor.replaceFirst('#', '');
            fontColor = Color(int.parse('FF$hex', radix: 16));
          } catch (_) {}
        }

        TextAlign align = TextAlign.center;
        if (txtEl.textAlign == 'left') align = TextAlign.left;
        if (txtEl.textAlign == 'right') align = TextAlign.right;

        final txtPngPath = '${jobDir.path}/txt_$i.png';
        final txtFile = await _renderTextToPng(
          text: textVal,
          fontFamily: txtEl.fontFamily.isNotEmpty ? txtEl.fontFamily : 'Cinzel',
          fontSize: fontSize,
          color: fontColor,
          align: align,
          maxWidth: (1600 * scaleFactor),
          outputPath: txtPngPath,
          rotation: txtEl.rotation,
        );

        // Get image dimensions for positioning
        final decodedImg = await decodeImageFromList(await txtFile.readAsBytes());
        final bw = decodedImg.width;
        final bh = decodedImg.height;

        int ox;
        if (align == TextAlign.left) {
          ox = cx;
        } else if (align == TextAlign.right) {
          ox = cx - bw;
        } else {
          ox = cx - (bw ~/ 2);
        }
        final oy = cy - (bh ~/ 2);

        inputs.addAll(['-thread_queue_size', '16', '-loop', '1', '-t', dur.toStringAsFixed(2), '-i', txtPngPath]);
        final txtInputId = inputIdx++;
        final nextStream = 'v_txt_$i';

        filterChains.add(
          '[$txtInputId:v]format=rgba,fade=t=in:st=0:d=${fi.toStringAsFixed(2)}:alpha=1,fade=t=out:st=${(dur - fo).clamp(0, dur).toStringAsFixed(2)}:d=${fo.toStringAsFixed(2)}:alpha=1,setpts=PTS-STARTPTS+${st.toStringAsFixed(2)}/TB[txt_timed_$i]',
        );
        filterChains.add(
          '[$currentStream][txt_timed_$i]overlay=$ox:$oy:enable=\'between(t,${st.toStringAsFixed(2)},${et.toStringAsFixed(2)})\'[$nextStream]',
        );
        currentStream = nextStream;
      }

      final filterComplex = filterChains.join(';');
      final outputVideoPath = '${appDocsDir.path}/invitation_$timestamp.mp4';

      final List<String> ffmpegArgs = [
        '-y',
        ...inputs,
        '-filter_complex', filterComplex,
        '-map', '[$currentStream]',
        '-map', '0:a?',
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-crf', '25',
        '-tune', 'fastdecode',
        '-pix_fmt', 'yuv420p',
        '-c:a', 'aac',
        '-b:a', '192k',
        '-t', duration.toStringAsFixed(2),
        outputVideoPath,
      ];

      debugPrint('[OnDeviceRender] Launching native mobile FFmpeg command...');
      onProgress?.call(0.35, 'Encoding on phone processor...');

      final completer = Completer<Map<String, dynamic>>();

      FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
        final timeMs = stats.getTime();
        if (timeMs > 0 && duration > 0) {
          final progress = 0.35 + (timeMs / (duration * 1000.0)) * 0.60;
          onProgress?.call(progress.clamp(0.35, 0.96), 'Rendering invitation video on device...');
        }
      });

      await FFmpegKit.executeWithArgumentsAsync(ffmpegArgs, (Session session) async {
        final returnCode = await session.getReturnCode();
        if (ReturnCode.isSuccess(returnCode)) {
          debugPrint('[OnDeviceRender] Video render successful: $outputVideoPath');
          onProgress?.call(1.0, 'Video ready!');
          completer.complete({
            'success': true,
            'videoUrl': outputVideoPath,
            'downloadPath': outputVideoPath,
            'creationId': 'cr_$timestamp',
          });
        } else {
          final logs = await session.getAllLogsAsString();
          debugPrint('[OnDeviceRender] FFmpeg failed: $logs');
          completer.complete({
            'success': false,
            'error': 'On-device render error: return code $returnCode',
          });
        }
      });

      return await completer.future;
    } catch (e, stack) {
      debugPrint('[OnDeviceRender] Exception during local render: $e\n$stack');
      return {
        'success': false,
        'error': 'On-device video rendering failed: $e',
      };
    }
  }
}
