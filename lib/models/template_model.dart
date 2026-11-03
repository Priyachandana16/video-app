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
  final Map<String, dynamic>? timelineConfig;

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
    this.timelineConfig,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? 'Wedding',
      religion: json['religion'] ?? 'Hindu',
      orientation: json['orientation'] ?? '9:16',
      hasPhoto: json['hasPhoto'] == true,
      photoSlotsCount: json['photoSlotsCount'] ?? (json['hasPhoto'] == true ? 2 : 0),
      durationSeconds: json['durationSeconds'] ?? 12,
      badgeText: json['badgeText'] ?? '',
      description: json['description'] ?? '',
      masterVideoPath: json['masterVideoPath'] ?? 'assets/wedding_template_master.mp4',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      timelineConfig: json['timelineConfig'] as Map<String, dynamic>?,
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
      'timelineConfig': timelineConfig,
    };
  }
}
