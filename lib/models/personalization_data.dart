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
  String? primaryPhotoPath;
  Uint8List? primaryPhotoBytes;
  List<String> additionalPhotos;

  PersonalizationData({
    this.templateId = 'tmpl_hindu_royal_01',
    this.brideName = 'Ananya',
    this.groomName = 'Rajesh',
    this.parentsNames = 'Smt. Lakshmi & Sri. Venkat Rao',
    this.ceremonyTitle = 'Shubh Vivaham',
    this.eventDate = 'Sunday, 15 December 2026',
    this.muhurthamTime = 'Muhurtham: 09:45 AM',
    this.venue = 'The Grand Chola Palace, Chennai',
    this.rsvp = 'With Best Compliments from Family & Friends',
    this.contactPhone = '+91 98765 43210',
    this.hasPhoto = true,
    this.primaryPhotoPath,
    this.primaryPhotoBytes,
    List<String>? additionalPhotos,
  }) : additionalPhotos = additionalPhotos ?? [];

  String get coupleTitle => '$groomName & $brideName';

  Map<String, String> toFormFields() {
    return {
      'templateId': templateId,
      'hasPhoto': hasPhoto.toString(),
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
      primaryPhotoPath: primaryPhotoPath ?? this.primaryPhotoPath,
      primaryPhotoBytes: primaryPhotoBytes ?? this.primaryPhotoBytes,
      additionalPhotos: additionalPhotos ?? List.from(this.additionalPhotos),
    );
  }
}
