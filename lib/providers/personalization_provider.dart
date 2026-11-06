import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/personalization_data.dart';
import '../models/template_model.dart';
import '../models/creation_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class PersonalizationProvider extends ChangeNotifier {
  PersonalizationData _data = PersonalizationData();
  final ImagePicker _picker = ImagePicker();

  bool _isRendering = false;
  double _renderProgress = 0.01;
  String _renderStep = 'Preparing your invitation...';
  String? _renderedVideoUrl;
  String? _renderedLocalPath;
  String? _creationId;
  String? _renderError;

  List<CreationModel> _creations = [];
  bool _isLoadingCreations = false;

  PersonalizationData get data => _data;
  bool get isRendering => _isRendering;
  double get renderProgress => _renderProgress;
  String get renderStep => _renderStep;
  String? get renderedVideoUrl => _renderedVideoUrl;
  String? get renderedLocalPath => _renderedLocalPath;
  String? get creationId => _creationId;
  String? get renderError => _renderError;
  List<CreationModel> get creations => _creations;
  bool get isLoadingCreations => _isLoadingCreations;

  PersonalizationProvider() {
    loadCreations();
  }

  void updateTemplate(TemplateModel template) {
    _data.templateId = template.id;
    _data.hasPhoto = template.hasPhoto;
    notifyListeners();
  }

  void updateTemplateId(String templateId, {bool? hasPhoto}) {
    _data.templateId = templateId;
    if (hasPhoto != null) _data.hasPhoto = hasPhoto;
    notifyListeners();
  }

  void updateForm({
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
    String? womanPhotoPath,
    String? manPhotoPath,
  }) {
    _data = _data.copyWith(
      brideName: brideName,
      groomName: groomName,
      parentsNames: parentsNames,
      ceremonyTitle: ceremonyTitle,
      eventDate: eventDate,
      muhurthamTime: muhurthamTime,
      venue: venue,
      rsvp: rsvp,
      contactPhone: contactPhone,
      hasPhoto: hasPhoto,
      womanPhotoPath: womanPhotoPath,
      manPhotoPath: manPhotoPath,
    );
    notifyListeners();
  }

  void updatePhotoPlacement({
    required String placement,
    double scale = 1.0,
    double offsetX = 0.0,
    double offsetY = 0.0,
  }) {
    _data = _data.copyWith(
      photoPlacement: placement,
      photoScale: scale,
      photoOffsetX: offsetX,
      photoOffsetY: offsetY,
    );
    notifyListeners();
  }

  Future<void> pickWomanPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        _data.womanPhotoPath = image.path;
        _data.womanPhotoBytes = bytes;
        _data.primaryPhotoPath = image.path;
        _data.primaryPhotoBytes = bytes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking woman photo: $e');
    }
  }

  Future<void> pickManPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        _data.manPhotoPath = image.path;
        _data.manPhotoBytes = bytes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking man photo: $e');
    }
  }

  void removeWomanPhoto() {
    _data.womanPhotoPath = null;
    _data.womanPhotoBytes = null;
    notifyListeners();
  }

  void removeManPhoto() {
    _data.manPhotoPath = null;
    _data.manPhotoBytes = null;
    notifyListeners();
  }

  Future<void> pickSlotPhoto(String slotKey) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        _data.slotPhotoPaths[slotKey] = image.path;
        _data.slotPhotoBytes[slotKey] = bytes;
        if (slotKey == 'photo_1' || slotKey == 'womanPhoto') {
          _data.womanPhotoPath = image.path;
          _data.womanPhotoBytes = bytes;
          _data.primaryPhotoPath = image.path;
          _data.primaryPhotoBytes = bytes;
        } else if (slotKey == 'photo_2' || slotKey == 'manPhoto') {
          _data.manPhotoPath = image.path;
          _data.manPhotoBytes = bytes;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking photo for $slotKey: $e');
    }
  }

  void removeSlotPhoto(String slotKey) {
    _data.slotPhotoPaths.remove(slotKey);
    _data.slotPhotoBytes.remove(slotKey);
    if (slotKey == 'photo_1' || slotKey == 'womanPhoto') {
      _data.womanPhotoPath = null;
      _data.womanPhotoBytes = null;
      _data.primaryPhotoPath = null;
      _data.primaryPhotoBytes = null;
    } else if (slotKey == 'photo_2' || slotKey == 'manPhoto') {
      _data.manPhotoPath = null;
      _data.manPhotoBytes = null;
    }
    notifyListeners();
  }

  Future<void> pickPrimaryPhoto() async {
    await pickWomanPhoto();
  }

  Future<void> pickAdditionalPhoto() async {
    await pickManPhoto();
  }

  Future<bool> startRendering() async {
    if (_isRendering) return false;
    _isRendering = true;
    _renderProgress = 0.01;
    _renderStep = 'Preparing your invitation...';
    _renderError = null;
    notifyListeners();

    try {
      final result = await ApiService.instance.renderVideo(
        _data,
        onProgress: (progress, step) {
          if (progress > _renderProgress) {
            _renderProgress = progress.clamp(0.01, 1.0);
          }
          if (step.isNotEmpty) {
            _renderStep = step;
          }
          notifyListeners();
        },
      );

      if (result['success'] == true) {
        _renderProgress = 1.0;
        _renderStep = 'Video ready!';
        _renderedVideoUrl = result['videoUrl'];
        _renderedLocalPath = result['downloadPath'];
        _creationId = result['creationId'];
        _isRendering = false;

        final newCreation = CreationModel(
          id: _creationId ?? 'cr_${DateTime.now().millisecondsSinceEpoch}',
          title: '${_data.coupleTitle} ${_data.ceremonyTitle}',
          coupleNames: _data.coupleTitle,
          eventDate: _data.eventDate,
          venue: _data.venue,
          videoUrl: _renderedVideoUrl ?? 'assets/templates/template_01_sample_result.mp4',
          thumbnailUrl: 'assets/templates/thumb_01_green.jpg',
          createdAt: DateTime.now(),
        );

        _creations.insert(0, newCreation);
        await StorageService.instance.saveCreation(newCreation);

        notifyListeners();
        return true;
      } else {
        _renderError = result['error'] ?? 'Video rendering failed';
        _isRendering = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _renderError = e.toString();
      _isRendering = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadCreations() async {
    _isLoadingCreations = true;
    notifyListeners();

    try {
      final serverCreations = await ApiService.instance.getCreations();
      final localCreations = await StorageService.instance.getCreations();

      final Map<String, CreationModel> map = {};
      for (var c in localCreations) {
        map[c.id] = c;
      }
      for (var c in serverCreations) {
        map[c.id] = c;
      }

      _creations = map.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading creations: $e');
    } finally {
      _isLoadingCreations = false;
      notifyListeners();
    }
  }

  Future<String?> downloadToDevice() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _renderedLocalPath ?? 'Y:\\Video Invitation App !\\backend\\exports\\invitation_personalized.mp4';
  }

  void shareRenderedVideo() {
    debugPrint('Sharing invitation video: $_renderedVideoUrl');
  }

  void reset() {
    _data = PersonalizationData();
    _isRendering = false;
    _renderProgress = 0.01;
    _renderStep = 'Preparing your invitation...';
    _renderedVideoUrl = null;
    _renderedLocalPath = null;
    _creationId = null;
    _renderError = null;
    notifyListeners();
  }
}
