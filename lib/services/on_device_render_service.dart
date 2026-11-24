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
  /// Natively supports Telugu, Hindi, English, all Unicode wedding glyphs, custom weights, strokes, and rotation
  Future<File> _renderTextToPng({
    required String text,
    required String fontFamily,
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
    bool strokeEnabled = false,
    double strokeWidth = 2.0,
    Color strokeColor = Colors.black,
    required TextAlign align,
    required double maxWidth,
    required String outputPath,
    double rotation = 0.0,
  }) async {
    TextStyle style;
    final cleanFont = fontFamily.trim();

    try {
      style = GoogleFonts.getFont(
        cleanFont,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        shadows: strokeEnabled
            ? []
            : const [
                Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
              ],
      );
    } catch (_) {
      // Fallback for Telugu or bundled asset font
      style = TextStyle(
        fontFamily: cleanFont,
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        shadows: strokeEnabled
            ? []
            : const [
                Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
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
    final rad = rotation * math.pi / 180.0;

    if (rotation != 0.0) {
      bw = (tw * math.cos(rad).abs() + th * math.sin(rad).abs()).ceilToDouble() + 16.0;
      bh = (tw * math.sin(rad).abs() + th * math.cos(rad).abs()).ceilToDouble() + 16.0;
    }

    // Optional Stroke Outline rendering
    if (strokeEnabled && strokeWidth > 0) {
      final strokeSpan = TextSpan(
        text: text,
        style: style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = strokeColor,
          shadows: [],
        ),
      );
      final strokePainter = TextPainter(
        text: strokeSpan,
        textAlign: align,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth);

      if (rotation != 0.0) {
        canvas.save();
        canvas.translate(bw / 2, bh / 2);
        canvas.rotate(rad);
        strokePainter.paint(canvas, Offset(-tw / 2 + 8, -th / 2 + 8));
        canvas.restore();
      } else {
        strokePainter.paint(canvas, const Offset(8, 8));
      }
    }

    // Main Fill Typography
    if (rotation != 0.0) {
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

  /// Render photo slot to transparent PNG with accurate scaling, offset positioning, and shape clipping
  Future<File> _renderPhotoSlotToPng({
    required String? photoPath,
    required Uint8List? photoBytes,
    required int targetW,
    required int targetH,
    required double scale,
    required double offsetX,
    required double offsetY,
    required String shape,
    required String outputPath,
    double rotation = 0.0,
  }) async {
    ui.Image img;
    try {
      if (photoBytes != null && photoBytes.isNotEmpty) {
        img = await decodeImageFromList(photoBytes);
      } else if (photoPath != null && await File(photoPath).exists()) {
        final bytes = await File(photoPath).readAsBytes();
        img = await decodeImageFromList(bytes);
      } else {
        final byteData = await rootBundle.load('assets/candidate_logo1.png');
        img = await decodeImageFromList(byteData.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('[OnDeviceRender] Photo decode failed: $e, using asset fallback');
      final byteData = await rootBundle.load('assets/candidate_logo1.png');
      img = await decodeImageFromList(byteData.buffer.asUint8List());
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final rect = Rect.fromLTWH(0, 0, targetW.toDouble(), targetH.toDouble());

    // 1. Shape clipping (matches in-app preview exactly)
    final path = Path();
    if (shape == 'circle') {
      final minDim = math.min(targetW, targetH).toDouble();
      final circleRect = Rect.fromCenter(
        center: Offset(targetW / 2.0, targetH / 2.0),
        width: minDim,
        height: minDim,
      );
      path.addOval(circleRect);
      canvas.clipPath(path);
    } else if (shape == 'oval') {
      path.addOval(rect);
      canvas.clipPath(path);
    } else if (shape == 'rounded') {
      final radius = Radius.circular(math.min(targetW, targetH) * 0.18);
      path.addRRect(RRect.fromRectAndRadius(rect, radius));
      canvas.clipPath(path);
    } else {
      // Rectangle
      path.addRect(rect);
      canvas.clipPath(path);
    }

    // 2. Compute Cover Scaling & User Zoom
    final double imgW = img.width.toDouble();
    final double imgH = img.height.toDouble();
    final double baseScale = math.max(targetW / imgW, targetH / imgH);
    final double totalScale = baseScale * (scale > 0 ? scale : 1.0);

    final double drawW = imgW * totalScale;
    final double drawH = imgH * totalScale;

    // Offset is calibrated to target slot size
    final double drawX = (targetW - drawW) / 2.0 + (offsetX * (targetW / 130.0));
    final double drawY = (targetH - drawH) / 2.0 + (offsetY * (targetH / 130.0));

    if (rotation != 0.0) {
      canvas.save();
      canvas.translate(targetW / 2.0, targetH / 2.0);
      canvas.rotate(rotation * math.pi / 180.0);
      canvas.translate(-targetW / 2.0, -targetH / 2.0);
    }

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, imgW, imgH),
      Rect.fromLTWH(drawX, drawY, drawW, drawH),
      paint,
    );

    if (rotation != 0.0) {
      canvas.restore();
    }

    final picture = recorder.endRecording();
    final renderedImg = await picture.toImage(targetW, targetH);
    final byteData = await renderedImg.toByteData(format: ui.ImageByteFormat.png);

    final outFile = File(outputPath);
    await outFile.writeAsBytes(byteData!.buffer.asUint8List());
    return outFile;
  }

  /// Main On-Device Render Execution
  Future<Map<String, dynamic>> renderOnDevice(
    PersonalizationData data, {
    TemplateModel? template,
    void Function(double progress, String step)? onProgress,
  }) async {
    try {
      onProgress?.call(0.05, 'Initializing hardware video engine...');
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
      onProgress?.call(0.12, 'Loading template master video...');
      final masterVideoPath = await _resolveMasterVideo(activeTemplate, onProgress: onProgress);

      final origCanvasW = activeTemplate.canvasWidth > 0 ? activeTemplate.canvasWidth : 1920;
      final origCanvasH = activeTemplate.canvasHeight > 0 ? activeTemplate.canvasHeight : 1080;
      // 720p HD resolution provides lightning fast 60fps encoding on mobile hardware
      final canvasW = origCanvasW > 1280 ? 1280 : origCanvasW;
      final canvasH = (origCanvasH * (canvasW / origCanvasW)).round();
      final double scaleFactor = canvasW / origCanvasW.toDouble();

      final List<String> inputs = ['-thread_queue_size', '16', '-i', masterVideoPath];
      final List<String> filterChains = [];

      // Optional Master Video Chroma Key (RGB Colorkey)
      final bool masterChromaEnabled = activeTemplate.masterVideoChromaKey;
      String currentStream = 'v_canvas';
      int inputIdx = 1;

      if (masterChromaEnabled) {
        final hex = activeTemplate.masterVideoChromaKeyColor.replaceAll('#', '').toLowerCase();
        final rawSim = activeTemplate.masterVideoChromaKeySimilarity;
        final sim = rawSim >= 0.15 ? rawSim.clamp(0.15, 0.60) : 0.38;
        final blend = activeTemplate.masterVideoChromaKeyBlend > 0
            ? activeTemplate.masterVideoChromaKeyBlend.clamp(0.01, 0.30)
            : 0.12;
        // 1. Scale and apply colorkey (RGB distance removal) to master video
        filterChains.add(
          '[0:v]scale=$canvasW:$canvasH:force_original_aspect_ratio=decrease,pad=$canvasW:$canvasH:(ow-iw)/2:(oh-ih)/2,setsar=1,format=rgba,colorkey=0x$hex:$sim:$blend[v_master_keyed]',
        );
        // 2. Base canvas for photos
        filterChains.add('color=c=black:s=${canvasW}x$canvasH:d=${duration.toStringAsFixed(2)}[v_canvas]');
        currentStream = 'v_canvas';
      } else {
        filterChains.add(
          '[0:v]scale=$canvasW:$canvasH:force_original_aspect_ratio=decrease,pad=$canvasW:$canvasH:(ow-iw)/2:(oh-ih)/2,setsar=1[v_canvas]',
        );
        currentStream = 'v_canvas';
      }

      // 1. Process Uploaded Photos (Multi-Photo Slots)
      if (data.hasPhoto && activeTemplate.imageElements.isNotEmpty) {
        onProgress?.call(0.20, 'Composing portrait photos & shapes...');
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

          final slotScale = data.getSlotScale(fieldName);
          final slotOffX = data.getSlotOffsetX(fieldName);
          final slotOffY = data.getSlotOffsetY(fieldName);
          final slotShape = data.getSlotShape(fieldName).isNotEmpty && data.getSlotShape(fieldName) != 'rectangle'
              ? data.getSlotShape(fieldName)
              : imgEl.shape;

          // Find picked photo path or bytes on device
          String? photoPath = data.getSlotPhotoPath(fieldName);
          Uint8List? photoBytes = data.getSlotPhotoBytes(fieldName);
          if ((photoPath == null || !File(photoPath).existsSync()) && photoBytes == null) {
            photoPath = data.primaryPhotoPath;
            photoBytes = data.primaryPhotoBytes;
          }

          final isVideo = photoPath != null && (
              photoPath.toLowerCase().endsWith('.mp4') ||
              photoPath.toLowerCase().endsWith('.mov') ||
              photoPath.toLowerCase().endsWith('.webm'));

          if (isVideo) {
            inputs.addAll(['-thread_queue_size', '16', '-stream_loop', '-1', '-t', dur.toStringAsFixed(2), '-i', photoPath]);
            final photoInputId = inputIdx++;
            final nextStream = 'v_img_$i';

            final scaledW = (w * slotScale).round();
            final scaledH = (h * slotScale).round();
            final ox = slotOffX.round();
            final oy = slotOffY.round();

            String imgFilters = 'scale=$scaledW:$scaledH:force_original_aspect_ratio=increase,crop=$w:$h:max(0\\,min(in_w-$w\\,(in_w-$w)/2+($ox))):max(0\\,min(in_h-$h\\,(in_h-$h)/2+($oy)))';

            if (slotShape == 'circle' || slotShape == 'oval') {
              imgFilters += ',format=rgba,geq=r=\'r(X,Y)\':g=\'g(X,Y)\':b=\'b(X,Y)\':a=\'if(lte(pow((X-W/2)/(W/2),2)+pow((Y-H/2)/(H/2),2),1),255,0)\'';
            }

            if (imgEl.chromaKey) {
              final hex = imgEl.chromaKeyColor.replaceAll('#', '').toLowerCase();
              if (hex.length == 6) {
                final sim = imgEl.chromaKeySimilarity > 0 ? imgEl.chromaKeySimilarity : 0.38;
                final blend = imgEl.chromaKeyBlend > 0 ? imgEl.chromaKeyBlend : 0.12;
                imgFilters += ',format=rgba,colorkey=0x$hex:$sim:$blend';
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
          } else {
            // High-fidelity pre-rendered photo slot with exact zoom, centering/offsets, and anti-aliased shape masking
            final prepPngPath = '${jobDir.path}/prep_photo_$i.png';
            await _renderPhotoSlotToPng(
              photoPath: photoPath,
              photoBytes: photoBytes,
              targetW: w,
              targetH: h,
              scale: slotScale,
              offsetX: slotOffX,
              offsetY: slotOffY,
              shape: slotShape,
              outputPath: prepPngPath,
              rotation: imgEl.rotation,
            );

            inputs.addAll(['-thread_queue_size', '16', '-framerate', '25', '-loop', '1', '-t', dur.toStringAsFixed(2), '-i', prepPngPath]);
            final photoInputId = inputIdx++;
            final nextStream = 'v_img_$i';

            String imgFilters = 'format=rgba';
            if (imgEl.chromaKey) {
              final hex = imgEl.chromaKeyColor.replaceAll('#', '').toLowerCase();
              if (hex.length == 6) {
                final sim = imgEl.chromaKeySimilarity > 0 ? imgEl.chromaKeySimilarity : 0.38;
                final blend = imgEl.chromaKeyBlend > 0 ? imgEl.chromaKeyBlend : 0.12;
                imgFilters += ',colorkey=0x$hex:$sim:$blend';
              }
            }

            imgFilters += ',fade=t=in:st=0:d=${animDur.toStringAsFixed(2)}:alpha=1,fade=t=out:st=${(dur - fadeOut).clamp(0, dur).toStringAsFixed(2)}:d=${fadeOut.toStringAsFixed(2)}:alpha=1,setpts=PTS-STARTPTS+${st.toStringAsFixed(2)}/TB';

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

      if (masterChromaEnabled) {
        // Overlay the keyed master green-screen video frame ON TOP OF the photos
        // so photos reveal through the transparent green cutouts
        final nextStream = 'v_chroma_composite';
        filterChains.add('[$currentStream][v_master_keyed]overlay=0:0[$nextStream]');
        currentStream = nextStream;
      }

      // 2. Process Dynamic Typography Overlays (Telugu & English)
      onProgress?.call(0.28, 'Rendering sacred typography & titles...');
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

        FontWeight fw = FontWeight.normal;
        if (txtEl.fontWeight == 'light' || txtEl.fontWeight == '300') {
          fw = FontWeight.w300;
        } else if (txtEl.fontWeight == 'bold' || txtEl.fontWeight == '700') {
          fw = FontWeight.bold;
        }

        Color strokeCol = Colors.black;
        if (txtEl.strokeColor.isNotEmpty) {
          try {
            final hex = txtEl.strokeColor.replaceFirst('#', '');
            strokeCol = Color(int.parse('FF$hex', radix: 16));
          } catch (_) {}
        }

        TextAlign align = TextAlign.center;
        if (txtEl.textAlign == 'left') align = TextAlign.left;
        if (txtEl.textAlign == 'right') align = TextAlign.right;

        final txtPngPath = '${jobDir.path}/txt_$i.png';
        final txtFile = await _renderTextToPng(
          text: textVal,
          fontFamily: txtEl.fontFamily.isNotEmpty ? txtEl.fontFamily : 'Ponnala',
          fontSize: fontSize,
          color: fontColor,
          fontWeight: fw,
          strokeEnabled: txtEl.strokeEnabled,
          strokeWidth: (txtEl.strokeWidth * scaleFactor).clamp(1.0, 8.0),
          strokeColor: strokeCol,
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

        inputs.addAll(['-thread_queue_size', '16', '-framerate', '25', '-loop', '1', '-t', dur.toStringAsFixed(2), '-i', txtPngPath]);
        final txtInputId = inputIdx++;
        final nextStream = 'v_txt_$i';

        final animType = txtEl.animationType.toLowerCase().trim();
        final animDur = txtEl.animationDuration > 0
            ? txtEl.animationDuration.clamp(0.2, dur)
            : fi.clamp(0.2, dur);

        String txtFilter;
        String overlayFilter;

        if (animType == 'typewriter') {
          // True progressive character reveal wipe from left to right across animDur using frame counter N
          txtFilter = '[$txtInputId:v]format=rgba,geq=r=\'r(X,Y)\':g=\'g(X,Y)\':b=\'b(X,Y)\':a=\'if(lte(X,W*min(1,N/(25*${animDur.toStringAsFixed(2)}))),alpha(X,Y),0)\',fade=t=out:st=${(dur - fo).clamp(0, dur).toStringAsFixed(2)}:d=${fo.toStringAsFixed(2)}:alpha=1,setpts=PTS-STARTPTS+${st.toStringAsFixed(2)}/TB[txt_timed_$i]';
          overlayFilter = '[$currentStream][txt_timed_$i]overlay=$ox:$oy:enable=\'between(t,${st.toStringAsFixed(2)},${et.toStringAsFixed(2)})\'[$nextStream]';
        } else if (animType == 'circle_crop' || animType == 'circle') {
          // Circular aperture reveal expanding outwards from center
          txtFilter = '[$txtInputId:v]format=rgba,geq=r=\'r(X,Y)\':g=\'g(X,Y)\':b=\'b(X,Y)\':a=\'if(lte(hypot(X-W/2,Y-H/2),hypot(W/2,H/2)*min(1,N/(25*${animDur.toStringAsFixed(2)}))),alpha(X,Y),0)\',fade=t=out:st=${(dur - fo).clamp(0, dur).toStringAsFixed(2)}:d=${fo.toStringAsFixed(2)}:alpha=1,setpts=PTS-STARTPTS+${st.toStringAsFixed(2)}/TB[txt_timed_$i]';
          overlayFilter = '[$currentStream][txt_timed_$i]overlay=$ox:$oy:enable=\'between(t,${st.toStringAsFixed(2)},${et.toStringAsFixed(2)})\'[$nextStream]';
        } else if (animType == 'slide' || animType == 'slide_up' || animType == 'slide_in') {
          // Slide upwards smoothly into position with alpha fade
          txtFilter = '[$txtInputId:v]format=rgba,fade=t=in:st=0:d=${animDur.toStringAsFixed(2)}:alpha=1,fade=t=out:st=${(dur - fo).clamp(0, dur).toStringAsFixed(2)}:d=${fo.toStringAsFixed(2)}:alpha=1,setpts=PTS-STARTPTS+${st.toStringAsFixed(2)}/TB[txt_timed_$i]';
          overlayFilter = '[$currentStream][txt_timed_$i]overlay=$ox:\'if(lt(t-${st.toStringAsFixed(2)},${animDur.toStringAsFixed(2)}),$oy+50*(1-(t-${st.toStringAsFixed(2)})/${animDur.toStringAsFixed(2)}),$oy)\':enable=\'between(t,${st.toStringAsFixed(2)},${et.toStringAsFixed(2)})\'[$nextStream]';
        } else {
          // Default: clean cinematic alpha fade-in and fade-out
          txtFilter = '[$txtInputId:v]format=rgba,fade=t=in:st=0:d=${fi.toStringAsFixed(2)}:alpha=1,fade=t=out:st=${(dur - fo).clamp(0, dur).toStringAsFixed(2)}:d=${fo.toStringAsFixed(2)}:alpha=1,setpts=PTS-STARTPTS+${st.toStringAsFixed(2)}/TB[txt_timed_$i]';
          overlayFilter = '[$currentStream][txt_timed_$i]overlay=$ox:$oy:enable=\'between(t,${st.toStringAsFixed(2)},${et.toStringAsFixed(2)})\'[$nextStream]';
        }

        filterChains.add(txtFilter);
        filterChains.add(overlayFilter);
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
      onProgress?.call(0.35, 'Encoding on phone processor (35%)...');

      final completer = Completer<Map<String, dynamic>>();

      double currentSimProgress = 0.35;
      final progressTimer = Timer.periodic(const Duration(milliseconds: 320), (t) {
        if (currentSimProgress < 0.94) {
          currentSimProgress += 0.012;
          onProgress?.call(
            currentSimProgress,
            'Encoding invitation video on hardware (${(currentSimProgress * 100).toInt()}%)...',
          );
        }
      });

      FFmpegKitConfig.enableStatisticsCallback((Statistics stats) {
        final timeMs = stats.getTime();
        if (timeMs > 0 && duration > 0) {
          final progress = 0.35 + (timeMs / (duration * 1000.0)) * 0.60;
          if (progress > currentSimProgress) {
            currentSimProgress = progress.clamp(0.35, 0.96);
            onProgress?.call(
              currentSimProgress,
              'Encoding on phone processor (${(currentSimProgress * 100).toInt()}%)...',
            );
          }
        }
      });

      await FFmpegKit.executeWithArgumentsAsync(ffmpegArgs, (Session session) async {
        progressTimer.cancel();
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
