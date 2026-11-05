import 'dart:typed_data';

class PersonalizationData {
  String templateId;
  String brideName;
  String groomName;
  String parentsNames;
  String ceremonyTitle;
  String eventDate;
  String muhurthamTime;
  String venue;
  String rsvp;
  String contactPhone;
  bool hasPhoto;

  // Photo placement & positioning controls
  String photoPlacement; // 'arch_center', 'left', 'right', 'center'
  double photoScale; // 0.8 - 1.5
  double photoOffsetX; // -50.0 to 50.0
  double photoOffsetY; // -50.0 to 50.0
  
  // Specific photo slots for woman (Bride) and man (Groom)
  String? womanPhotoPath;
  Uint8List? womanPhotoBytes;
  String? manPhotoPath;
  Uint8List? manPhotoBytes;

  // Legacy fallback compatibility
  String? primaryPhotoPath;
  Uint8List? primaryPhotoBytes;
  List<String> additionalPhotos;

  PersonalizationData({
    this.templateId = 'tmpl_telugu_chroma_01',
    this.brideName = 'Deepika',
    this.groomName = 'Sai Krishna',
    this.parentsNames = 'Smt. Sarojini & Sri. Rama Rao',
    this.ceremonyTitle = 'శుభ వివాహం / Subha Vivaham',
    this.eventDate = 'Sunday, 15 December 2026',
    this.muhurthamTime = 'Sumuhurtham: 10:24 AM',
    this.venue = 'Sri Venkateswara Kalyana Mandapam, Hyderabad',
    this.rsvp = 'With Best Compliments from Family & Friends',
    this.contactPhone = '+91 98765 43210',
    this.hasPhoto = true,
    this.photoPlacement = 'arch_center',
    this.photoScale = 1.0,
    this.photoOffsetX = 0.0,
    this.photoOffsetY = 0.0,
    this.womanPhotoPath,
    this.womanPhotoBytes,
    this.manPhotoPath,
    this.manPhotoBytes,
    this.primaryPhotoPath,
    this.primaryPhotoBytes,
    List<String>? additionalPhotos,
  }) : additionalPhotos = additionalPhotos ?? [];

  String get coupleTitle => '$groomName & $brideName';

  Map<String, String> toFormFields() {
    return {
      'templateId': templateId,
      'hasPhoto': hasPhoto.toString(),
      'photoPlacement': photoPlacement,
      'photoScale': photoScale.toString(),
      'photoOffsetX': photoOffsetX.toString(),
      'photoOffsetY': photoOffsetY.toString(),
      'brideName': brideName,
      'groomName': groomName,
      'parentsNames': parentsNames,
      'ceremonyTitle': ceremonyTitle,
      'eventDate': eventDate,
      'muhurthamTime': muhurthamTime,
      'venue': venue,
      'rsvp': rsvp,
      'contactPhone': contactPhone,
    };
  }

  PersonalizationData copyWith({
    String? templateId,
    String? brideName,
    String? groomName,
    String? parentsNames,
    String? ceremonyTitle,
    String? eventDate,
    String? muhurthamTime,
    String? venue,
    String? rsvp,
    String? contactPhone,
    bool? hasPhoto,
    String? photoPlacement,
    double? photoScale,
    double? photoOffsetX,
    double? photoOffsetY,
    String? womanPhotoPath,
    Uint8List? womanPhotoBytes,
    String? manPhotoPath,
    Uint8List? manPhotoBytes,
    String? primaryPhotoPath,
    Uint8List? primaryPhotoBytes,
    List<String>? additionalPhotos,
  }) {
    return PersonalizationData(
      templateId: templateId ?? this.templateId,
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      parentsNames: parentsNames ?? this.parentsNames,
      ceremonyTitle: ceremonyTitle ?? this.ceremonyTitle,
      eventDate: eventDate ?? this.eventDate,
      muhurthamTime: muhurthamTime ?? this.muhurthamTime,
      venue: venue ?? this.venue,
      rsvp: rsvp ?? this.rsvp,
      contactPhone: contactPhone ?? this.contactPhone,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      photoPlacement: photoPlacement ?? this.photoPlacement,
      photoScale: photoScale ?? this.photoScale,
      photoOffsetX: photoOffsetX ?? this.photoOffsetX,
      photoOffsetY: photoOffsetY ?? this.photoOffsetY,
      womanPhotoPath: womanPhotoPath ?? this.womanPhotoPath,
      womanPhotoBytes: womanPhotoBytes ?? this.womanPhotoBytes,
      manPhotoPath: manPhotoPath ?? this.manPhotoPath,
      manPhotoBytes: manPhotoBytes ?? this.manPhotoBytes,
      primaryPhotoPath: primaryPhotoPath ?? this.primaryPhotoPath,
      primaryPhotoBytes: primaryPhotoBytes ?? this.primaryPhotoBytes,
      additionalPhotos: additionalPhotos ?? this.additionalPhotos,
    );
  }
}
