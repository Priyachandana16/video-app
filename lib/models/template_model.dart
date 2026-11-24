class TemplateTextElement {
  final String id;
  final String field;
  final String label;
  final String defaultText;
  final double x;
  final double y;
  final double fontSize;
  final String fontFamily;
  final String fontColor;
  final String fontWeight;
  final bool strokeEnabled;
  final double strokeWidth;
  final String strokeColor;
  final String animationType;
  final double animationDuration;
  final String textAlign;
  final double startTime;
  final double endTime;
  final double fadeIn;
  final double fadeOut;
  final double rotation;

  TemplateTextElement({
    required this.id,
    required this.field,
    required this.label,
    required this.defaultText,
    required this.x,
    required this.y,
    required this.fontSize,
    required this.fontFamily,
    required this.fontColor,
    this.fontWeight = 'normal',
    this.strokeEnabled = false,
    this.strokeWidth = 2.0,
    this.strokeColor = '#000000',
    this.animationType = 'fade',
    this.animationDuration = 0.8,
    required this.textAlign,
    required this.startTime,
    required this.endTime,
    required this.fadeIn,
    required this.fadeOut,
    this.rotation = 0.0,
  });

  factory TemplateTextElement.fromJson(Map<String, dynamic> json) {
    return TemplateTextElement(
      id: json['id'] ?? '',
      field: json['field'] ?? 'customText',
      label: json['label'] ?? '',
      defaultText: json['defaultText'] ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 40.0,
      fontFamily: json['fontFamily'] ?? 'Cinzel',
      fontColor: json['fontColor'] ?? '#FFD700',
      fontWeight: json['fontWeight']?.toString() ?? 'normal',
      strokeEnabled: json['strokeEnabled'] == true,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      strokeColor: json['strokeColor'] ?? '#000000',
      animationType: json['animationType'] ?? 'fade',
      animationDuration: (json['animationDuration'] as num?)?.toDouble() ?? 0.8,
      textAlign: json['textAlign'] ?? 'center',
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['endTime'] as num?)?.toDouble() ?? 10.0,
      fadeIn: (json['fadeIn'] as num?)?.toDouble() ?? 0.5,
      fadeOut: (json['fadeOut'] as num?)?.toDouble() ?? 0.5,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field': field,
      'label': label,
      'defaultText': defaultText,
      'x': x,
      'y': y,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'fontColor': fontColor,
      'fontWeight': fontWeight,
      'strokeEnabled': strokeEnabled,
      'strokeWidth': strokeWidth,
      'strokeColor': strokeColor,
      'animationType': animationType,
      'animationDuration': animationDuration,
      'textAlign': textAlign,
      'startTime': startTime,
      'endTime': endTime,
      'fadeIn': fadeIn,
      'fadeOut': fadeOut,
      'rotation': rotation,
    };
  }
}

class TemplateImageElement {
  final String id;
  final String field;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
  final String fit;
  final double startTime;
  final double endTime;
  final String animationType;
  final double animationDuration;
  final String shape;
  final String? placeholderUrl;
  final double rotation;
  final bool chromaKey;
  final String chromaKeyColor;
  final double chromaKeySimilarity;
  final double chromaKeyBlend;

  TemplateImageElement({
    required this.id,
    required this.field,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fit,
    required this.startTime,
    required this.endTime,
    required this.animationType,
    required this.animationDuration,
    this.shape = 'rectangle',
    this.placeholderUrl,
    this.rotation = 0.0,
    this.chromaKey = false,
    this.chromaKeyColor = '#00FF00',
    this.chromaKeySimilarity = 0.25,
    this.chromaKeyBlend = 0.05,
  });

  factory TemplateImageElement.fromJson(Map<String, dynamic> json) {
    return TemplateImageElement(
      id: json['id'] ?? '',
      field: json['field'] ?? 'photo_1',
      label: json['label'] ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 500.0,
      height: (json['height'] as num?)?.toDouble() ?? 600.0,
      fit: json['fit'] ?? 'cover',
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['endTime'] as num?)?.toDouble() ?? 10.0,
      animationType: json['animationType'] ?? 'fade',
      animationDuration: (json['animationDuration'] as num?)?.toDouble() ?? 1.2,
      shape: json['shape'] ?? 'rectangle',
      placeholderUrl: json['placeholderUrl'],
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      chromaKey: json['chromaKey'] == true || json['animationType'] == 'chroma_key',
      chromaKeyColor: json['chromaKeyColor'] ?? '#00FF00',
      chromaKeySimilarity: (json['chromaKeySimilarity'] as num?)?.toDouble() ?? 0.25,
      chromaKeyBlend: (json['chromaKeyBlend'] as num?)?.toDouble() ?? 0.05,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'field': field,
      'label': label,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'fit': fit,
      'startTime': startTime,
      'endTime': endTime,
      'animationType': animationType,
      'animationDuration': animationDuration,
      'shape': shape,
      'placeholderUrl': placeholderUrl,
      'rotation': rotation,
      'chromaKey': chromaKey,
      'chromaKeyColor': chromaKeyColor,
      'chromaKeySimilarity': chromaKeySimilarity,
      'chromaKeyBlend': chromaKeyBlend,
    };
  }
}

class TemplateModel {
  final String id;
  final String title;
  final String category;
  final String religion;
  final String orientation;
  final bool hasPhoto;
  final int photoSlotsCount;
  final int durationSeconds;
  final String badgeText;
  final String description;
  final String masterVideoPath;
  final String? videoUrl;
  final String thumbnailUrl;
  final String? sampleResultPath;
  final String? templateThumbUrl;
  final int canvasWidth;
  final int canvasHeight;
  final Map<String, dynamic>? timelineConfig;
  final bool masterVideoChromaKey;
  final String masterVideoChromaKeyColor;
  final double masterVideoChromaKeySimilarity;
  final double masterVideoChromaKeyBlend;
  final List<TemplateTextElement> textElements;
  final List<TemplateImageElement> imageElements;

  TemplateModel({
    required this.id,
    required this.title,
    required this.category,
    required this.religion,
    required this.orientation,
    required this.hasPhoto,
    required this.photoSlotsCount,
    required this.durationSeconds,
    required this.badgeText,
    required this.description,
    required this.masterVideoPath,
    required this.thumbnailUrl,
    this.videoUrl,
    this.sampleResultPath,
    this.templateThumbUrl,
    this.canvasWidth = 1920,
    this.canvasHeight = 1080,
    this.timelineConfig,
    this.masterVideoChromaKey = false,
    this.masterVideoChromaKeyColor = '#00FF00',
    this.masterVideoChromaKeySimilarity = 0.25,
    this.masterVideoChromaKeyBlend = 0.05,
    List<TemplateTextElement>? textElements,
    List<TemplateImageElement>? imageElements,
  })  : textElements = textElements ?? [],
        imageElements = imageElements ?? [];

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    var rawText = (json['textElements'] ?? json['text_elements']) as List?;
    var rawImage = (json['imageElements'] ?? json['image_elements']) as List?;
    Map<String, dynamic> config = {};

    // If Supabase returned template_versions join, extract full config!
    if (json['template_versions'] is List && (json['template_versions'] as List).isNotEmpty) {
      final versions = List<dynamic>.from(json['template_versions']);
      versions.sort((a, b) {
        final verA = (a is Map && a['version_number'] != null) ? (a['version_number'] as num) : 0;
        final verB = (b is Map && b['version_number'] != null) ? (b['version_number'] as num) : 0;
        return verB.compareTo(verA);
      });
      final first = versions.first;
      if (first is Map && first['config'] is Map) {
        config = Map<String, dynamic>.from(first['config'] as Map);
        if (rawText == null || rawText.isEmpty) {
          rawText = (config['textElements'] ?? config['text_elements']) as List?;
        }
        if (rawImage == null || rawImage.isEmpty) {
          rawImage = (config['imageElements'] ?? config['image_elements']) as List?;
        }
      }
    }

    List<TemplateTextElement> textList = [];
    if (rawText != null) {
      textList = rawText.map((e) => TemplateTextElement.fromJson(e as Map<String, dynamic>)).toList();
    }

    List<TemplateImageElement> imageList = [];
    if (rawImage != null) {
      imageList = rawImage.map((e) => TemplateImageElement.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Explicitly respect boolean hasPhoto / has_photo if defined in JSON or config
    final dynamic explicitHasPhoto = json['hasPhoto'] ?? json['has_photo'] ?? config['hasPhoto'] ?? config['has_photo'];
    final bool hasPhotoVal = explicitHasPhoto != null
        ? (explicitHasPhoto == true || explicitHasPhoto == 'true')
        : imageList.isNotEmpty;

    final dynamic rawSlots = json['photoSlotsCount'] ?? json['photo_slots_count'] ?? config['photoSlotsCount'] ?? config['photo_slots_count'];
    final int slotCount = rawSlots != null
        ? (rawSlots is num ? rawSlots.toInt() : int.tryParse(rawSlots.toString()) ?? 0)
        : (hasPhotoVal ? (imageList.isNotEmpty ? imageList.length : 2) : 0);

    final dynamic rawDuration = json['durationSeconds'] ?? json['duration_seconds'] ?? config['durationSeconds'] ?? config['duration_seconds'];
    final int duration = rawDuration is num ? rawDuration.toInt() : (int.tryParse(rawDuration?.toString() ?? '60') ?? 60);

    // Master Video Chroma Key Resolution
    bool resolvedMasterChroma = json['masterVideoChromaKey'] == true ||
        json['master_video_chroma_key'] == true ||
        config['masterVideoChromaKey'] == true ||
        config['master_video_chroma_key'] == true;

    final String tid = (json['id'] ?? '').toString().toLowerCase();
    final String badge = (json['badgeText'] ?? json['badge_text'] ?? config['badgeText'] ?? '').toString().toLowerCase();
    final String mvPath = (json['masterVideoPath'] ?? json['master_video_url'] ?? json['videoUrl'] ?? config['masterVideoPath'] ?? config['videoUrl'] ?? '').toString().toLowerCase();
    if (!resolvedMasterChroma) {
      if (tid.contains('chroma') || badge.contains('chroma') || mvPath.contains('green_screen') || mvPath.contains('chroma')) {
        resolvedMasterChroma = true;
      }
    }

    final String chromaColor = (config['masterVideoChromaKeyColor'] ??
        config['master_video_chroma_key_color'] ??
        json['masterVideoChromaKeyColor'] ??
        json['master_video_chroma_key_color'] ??
        '#00FF00').toString();

    final double rawSim = (config['masterVideoChromaKeySimilarity'] ??
            config['master_video_chroma_key_similarity'] ??
            json['masterVideoChromaKeySimilarity'] ??
            json['master_video_chroma_key_similarity'] as num?)
        ?.toDouble() ??
        0.32;
    final double chromaSim = rawSim < 0.15 ? 0.32 : rawSim.clamp(0.15, 0.60);

    final double chromaBlend = (config['masterVideoChromaKeyBlend'] ??
            config['master_video_chroma_key_blend'] ??
            json['masterVideoChromaKeyBlend'] ??
            json['master_video_chroma_key_blend'] as num?)
        ?.toDouble() ??
        0.10;

    return TemplateModel(
      id: json['id'] ?? '',
      title: json['title'] ?? config['title'] ?? '',
      category: json['category'] ?? config['category'] ?? 'Wedding',
      religion: json['religion'] ?? config['religion'] ?? 'Hindu',
      orientation: json['orientation'] ?? config['orientation'] ?? '9:16',
      hasPhoto: hasPhotoVal,
      photoSlotsCount: slotCount,
      durationSeconds: duration,
      badgeText: json['badgeText'] ?? json['badge_text'] ?? config['badgeText'] ?? '',
      description: json['description'] ?? config['description'] ?? '',
      masterVideoPath: json['masterVideoPath'] ?? json['master_video_url'] ?? json['videoUrl'] ?? config['masterVideoPath'] ?? config['videoUrl'] ?? 'assets/wedding_template_master.mp4',
      videoUrl: json['videoUrl'] ?? json['video_url'] ?? json['masterVideoPath'] ?? json['master_video_url'] ?? config['videoUrl'] ?? config['masterVideoPath'],
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'] ?? config['thumbnailUrl'] ?? '',
      sampleResultPath: json['sampleResultPath'] ?? json['sample_result_url'] ?? config['sampleResultPath'] ?? config['sampleResultUrl'],
      templateThumbUrl: json['templateThumbUrl'] ?? json['thumbnail_url'] ?? config['thumbnailUrl'],
      canvasWidth: (json['canvasWidth'] ?? json['canvas_width'] ?? config['canvasWidth'] as num?)?.toInt() ?? 1920,
      canvasHeight: (json['canvasHeight'] ?? json['canvas_height'] ?? config['canvasHeight'] as num?)?.toInt() ?? 1080,
      timelineConfig: (json['timelineConfig'] ?? json['timeline_config'] ?? config['timelineConfig']) as Map<String, dynamic>?,
      masterVideoChromaKey: resolvedMasterChroma,
      masterVideoChromaKeyColor: chromaColor,
      masterVideoChromaKeySimilarity: chromaSim,
      masterVideoChromaKeyBlend: chromaBlend,
      textElements: textList,
      imageElements: imageList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'religion': religion,
      'orientation': orientation,
      'hasPhoto': hasPhoto,
      'photoSlotsCount': photoSlotsCount,
      'durationSeconds': durationSeconds,
      'badgeText': badgeText,
      'description': description,
      'masterVideoPath': masterVideoPath,
      'thumbnailUrl': thumbnailUrl,
      'sampleResultPath': sampleResultPath,
      'templateThumbUrl': templateThumbUrl,
      'timelineConfig': timelineConfig,
      'masterVideoChromaKey': masterVideoChromaKey,
      'masterVideoChromaKeyColor': masterVideoChromaKeyColor,
      'masterVideoChromaKeySimilarity': masterVideoChromaKeySimilarity,
      'masterVideoChromaKeyBlend': masterVideoChromaKeyBlend,
      'textElements': textElements.map((e) => e.toJson()).toList(),
      'imageElements': imageElements.map((e) => e.toJson()).toList(),
    };
  }
}
