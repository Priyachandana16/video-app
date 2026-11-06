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
    var rawText = json['textElements'] as List?;
    List<TemplateTextElement> textList = [];
    if (rawText != null) {
      textList = rawText.map((e) => TemplateTextElement.fromJson(e as Map<String, dynamic>)).toList();
    }

    var rawImage = json['imageElements'] as List?;
    List<TemplateImageElement> imageList = [];
    if (rawImage != null) {
      imageList = rawImage.map((e) => TemplateImageElement.fromJson(e as Map<String, dynamic>)).toList();
    }

    final hasPhotoVal = json['hasPhoto'] == true || imageList.isNotEmpty;
    final slotCount = imageList.isNotEmpty ? imageList.length : (json['photoSlotsCount'] ?? (hasPhotoVal ? 2 : 0));

    return TemplateModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Wedding',
      religion: json['religion'] ?? 'Hindu',
      orientation: json['orientation'] ?? '9:16',
      hasPhoto: hasPhotoVal,
      photoSlotsCount: slotCount,
      durationSeconds: json['durationSeconds'] ?? 60,
      badgeText: json['badgeText'] ?? '',
      description: json['description'] ?? '',
      masterVideoPath: json['masterVideoPath'] ?? 'assets/wedding_template_master.mp4',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      sampleResultPath: json['sampleResultPath'],
      templateThumbUrl: json['templateThumbUrl'],
      timelineConfig: json['timelineConfig'] as Map<String, dynamic>?,
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
