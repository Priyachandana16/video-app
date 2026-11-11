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

  // Multi-slot dynamic photo mapping (photo_1, photo_2, photo_3, photo_4, photo_5, etc.)
  Map<String, String> slotPhotoPaths;
  Map<String, Uint8List> slotPhotoBytes;

  // Dynamic custom text elements mapped directly from published Template textElements
  Map<String, String> customTextValues;

  // Specific legacy photo slots for woman (Bride) and man (Groom)
  String? womanPhotoPath;
  Uint8List? womanPhotoBytes;
  String? manPhotoPath;
  Uint8List? manPhotoBytes;

  // Fallback compatibility
  String? primaryPhotoPath;
  Uint8List? primaryPhotoBytes;
  List<String> additionalPhotos;

  PersonalizationData({
    this.templateId = '',
    this.brideName = '',
    this.groomName = '',
    this.parentsNames = '',
    this.ceremonyTitle = '',
    this.eventDate = '',
    this.muhurthamTime = '',
    this.venue = '',
    this.rsvp = '',
    this.contactPhone = '',
    this.hasPhoto = true,
    this.photoPlacement = 'arch_center',
    this.photoScale = 1.0,
    this.photoOffsetX = 0.0,
    this.photoOffsetY = 0.0,
    Map<String, String>? slotPhotoPaths,
    Map<String, Uint8List>? slotPhotoBytes,
    Map<String, String>? customTextValues,
    this.womanPhotoPath,
    this.womanPhotoBytes,
    this.manPhotoPath,
    this.manPhotoBytes,
    this.primaryPhotoPath,
    this.primaryPhotoBytes,
    List<String>? additionalPhotos,
  })  : slotPhotoPaths = slotPhotoPaths ?? {},
        slotPhotoBytes = slotPhotoBytes ?? {},
        customTextValues = customTextValues ?? {},
        additionalPhotos = additionalPhotos ?? [];

  String get coupleTitle {
    if (groomName.isNotEmpty && brideName.isNotEmpty) {
      return '$groomName & $brideName';
    }
    if (groomName.isNotEmpty) return groomName;
    if (brideName.isNotEmpty) return brideName;
    return '';
  }

  String getCustomText(String key, {String fallback = ''}) {
    if (customTextValues.containsKey(key) && customTextValues[key]!.isNotEmpty) {
      return customTextValues[key]!;
    }
    switch (key) {
      case 'brideName':
        return brideName.isNotEmpty ? brideName : fallback;
      case 'groomName':
        return groomName.isNotEmpty ? groomName : fallback;
      case 'ceremonyTitle':
        return ceremonyTitle.isNotEmpty ? ceremonyTitle : fallback;
      case 'eventDate':
        return eventDate.isNotEmpty ? eventDate : fallback;
      case 'muhurthamTime':
        return muhurthamTime.isNotEmpty ? muhurthamTime : fallback;
      case 'venue':
        return venue.isNotEmpty ? venue : fallback;
      case 'rsvp':
        return rsvp.isNotEmpty ? rsvp : fallback;
      case 'parentsNames':
        return parentsNames.isNotEmpty ? parentsNames : fallback;
      case 'contactPhone':
        return contactPhone.isNotEmpty ? contactPhone : fallback;
      default:
        return fallback;
    }
  }

  void setCustomText(String key, String value) {
    customTextValues[key] = value;
    switch (key) {
      case 'brideName':
        brideName = value;
        break;
      case 'groomName':
        groomName = value;
        break;
      case 'ceremonyTitle':
        ceremonyTitle = value;
        break;
      case 'eventDate':
        eventDate = value;
        break;
      case 'muhurthamTime':
        muhurthamTime = value;
        break;
      case 'venue':
        venue = value;
        break;
      case 'rsvp':
        rsvp = value;
        break;
      case 'parentsNames':
        parentsNames = value;
        break;
      case 'contactPhone':
        contactPhone = value;
        break;
    }
  }

  String? getSlotPhotoPath(String slotKey) {
    if (slotPhotoPaths.containsKey(slotKey) && slotPhotoPaths[slotKey] != null) {
      return slotPhotoPaths[slotKey];
    }
    if (slotKey == 'photo_1' || slotKey == 'womanPhoto') return womanPhotoPath;
    if (slotKey == 'photo_2' || slotKey == 'manPhoto') return manPhotoPath;
    if (slotKey == 'photo') return primaryPhotoPath;
    return null;
  }

  Uint8List? getSlotPhotoBytes(String slotKey) {
    if (slotPhotoBytes.containsKey(slotKey) && slotPhotoBytes[slotKey] != null) {
      return slotPhotoBytes[slotKey];
    }
    if (slotKey == 'photo_1' || slotKey == 'womanPhoto') return womanPhotoBytes;
    if (slotKey == 'photo_2' || slotKey == 'manPhoto') return manPhotoBytes;
    if (slotKey == 'photo') return primaryPhotoBytes;
    return null;
  }

  void clearPhotos() {
    slotPhotoPaths.clear();
    slotPhotoBytes.clear();
    womanPhotoPath = null;
    womanPhotoBytes = null;
    manPhotoPath = null;
    manPhotoBytes = null;
    primaryPhotoPath = null;
    primaryPhotoBytes = null;
    additionalPhotos.clear();
    photoPlacement = 'arch_center';
    photoScale = 1.0;
    photoOffsetX = 0.0;
    photoOffsetY = 0.0;
  }

  Map<String, String> toFormFields() {
    final fields = {
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

    // Forward all dynamic text elements configured from Admin Panel
    customTextValues.forEach((k, v) {
      fields[k] = v;
    });

    if (hasPhoto) {
      slotPhotoPaths.forEach((k, v) {
        fields['${k}Path'] = v;
      });

      if (womanPhotoPath != null) fields['womanPhotoPath'] = womanPhotoPath!;
      if (manPhotoPath != null) fields['manPhotoPath'] = manPhotoPath!;
      if (primaryPhotoPath != null) fields['photoPath'] = primaryPhotoPath!;
    }

    return fields;
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
    Map<String, String>? slotPhotoPaths,
    Map<String, Uint8List>? slotPhotoBytes,
    Map<String, String>? customTextValues,
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
      slotPhotoPaths: slotPhotoPaths ?? Map.from(this.slotPhotoPaths),
      slotPhotoBytes: slotPhotoBytes ?? Map.from(this.slotPhotoBytes),
      customTextValues: customTextValues ?? Map.from(this.customTextValues),
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
