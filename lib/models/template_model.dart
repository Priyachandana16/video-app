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
  final String textAlign;
  final double startTime;
  final double endTime;
  final double fadeIn;
  final double fadeOut;

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
    required this.textAlign,
    required this.startTime,
    required this.endTime,
    required this.fadeIn,
    required this.fadeOut,
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
      textAlign: json['textAlign'] ?? 'center',
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      endTime: (json['endTime'] as num?)?.toDouble() ?? 10.0,
      fadeIn: (json['fadeIn'] as num?)?.toDouble() ?? 0.5,
      fadeOut: (json['fadeOut'] as num?)?.toDouble() ?? 0.5,
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
      'textAlign': textAlign,
      'startTime': startTime,
      'endTime': endTime,
      'fadeIn': fadeIn,
      'fadeOut': fadeOut,
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
  final String? placeholderUrl;

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
    this.placeholderUrl,
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
      placeholderUrl: json['placeholderUrl'],
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
      'placeholderUrl': placeholderUrl,
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
  final String thumbnailUrl;
  final String? sampleResultPath;
  final String? templateThumbUrl;
  final Map<String, dynamic>? timelineConfig;
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
    this.sampleResultPath,
    this.templateThumbUrl,
    this.timelineConfig,
    List<TemplateTextElement>? textElements,
    List<TemplateImageElement>? imageElements,
  })  : textElements = textElements ?? [],
        imageElements = imageElements ?? [];

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    var rawText = (json['textElements'] ?? json['text_elements']) as List?;
    var rawImage = (json['imageElements'] ?? json['image_elements']) as List?;

    // If Supabase returned template_versions join, extract config for textElements and imageElements!
    if (json['template_versions'] is List && (json['template_versions'] as List).isNotEmpty) {
      final versions = List<dynamic>.from(json['template_versions']);
      versions.sort((a, b) {
        final verA = (a is Map && a['version_number'] != null) ? (a['version_number'] as num) : 0;
        final verB = (b is Map && b['version_number'] != null) ? (b['version_number'] as num) : 0;
        return verB.compareTo(verA);
      });
      final first = versions.first;
      if (first is Map && first['config'] is Map) {
        final config = first['config'] as Map<String, dynamic>;
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

    // Explicitly respect boolean hasPhoto / has_photo if defined in JSON
    final dynamic explicitHasPhoto = json['hasPhoto'] ?? json['has_photo'];
    final bool hasPhotoVal = explicitHasPhoto != null
        ? (explicitHasPhoto == true || explicitHasPhoto == 'true')
        : imageList.isNotEmpty;

    final dynamic rawSlots = json['photoSlotsCount'] ?? json['photo_slots_count'];
    final int slotCount = rawSlots != null
        ? (rawSlots is num ? rawSlots.toInt() : int.tryParse(rawSlots.toString()) ?? 0)
        : (hasPhotoVal ? (imageList.isNotEmpty ? imageList.length : 2) : 0);

    final dynamic rawDuration = json['durationSeconds'] ?? json['duration_seconds'];
    final int duration = rawDuration is num ? rawDuration.toInt() : (int.tryParse(rawDuration?.toString() ?? '60') ?? 60);

    return TemplateModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Wedding',
      religion: json['religion'] ?? 'Hindu',
      orientation: json['orientation'] ?? '9:16',
      hasPhoto: hasPhotoVal,
      photoSlotsCount: slotCount,
      durationSeconds: duration,
      badgeText: json['badgeText'] ?? json['badge_text'] ?? '',
      description: json['description'] ?? '',
      masterVideoPath: json['masterVideoPath'] ?? json['master_video_url'] ?? 'assets/wedding_template_master.mp4',
      thumbnailUrl: json['thumbnailUrl'] ?? json['thumbnail_url'] ?? '',
      sampleResultPath: json['sampleResultPath'] ?? json['sample_result_url'],
      templateThumbUrl: json['templateThumbUrl'] ?? json['thumbnail_url'],
      timelineConfig: (json['timelineConfig'] ?? json['timeline_config']) as Map<String, dynamic>?,
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
      'textElements': textElements.map((e) => e.toJson()).toList(),
      'imageElements': imageElements.map((e) => e.toJson()).toList(),
    };
  }
}
