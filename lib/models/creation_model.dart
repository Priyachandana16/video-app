class CreationModel {
  final String id;
  final String title;
  final String coupleNames;
  final String eventDate;
  final String venue;
  final String videoUrl;
  final String? localFilePath;
  final String thumbnailUrl;
  final DateTime createdAt;

  CreationModel({
    required this.id,
    required this.title,
    required this.coupleNames,
    required this.eventDate,
    required this.venue,
    required this.videoUrl,
    this.localFilePath,
    required this.thumbnailUrl,
    required this.createdAt,
  });

  factory CreationModel.fromJson(Map<String, dynamic> json) {
    return CreationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      coupleNames: json['coupleNames'] ?? '',
      eventDate: json['eventDate'] ?? '',
      venue: json['venue'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      localFilePath: json['localFilePath'] ?? json['downloadPath'],
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coupleNames': coupleNames,
      'eventDate': eventDate,
      'venue': venue,
      'videoUrl': videoUrl,
      'localFilePath': localFilePath,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
