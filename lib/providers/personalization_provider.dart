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
  double _renderProgress = 0.0;
  String? _renderedVideoUrl;
  String? _renderedLocalPath;
  String? _creationId;
  String? _renderError;

  List<CreationModel> _creations = [];
  bool _isLoadingCreations = false;

  PersonalizationData get data => _data;
  bool get isRendering => _isRendering;
  double get renderProgress => _renderProgress;
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
    );
    notifyListeners();
  }

  Future<void> pickPrimaryPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        _data.primaryPhotoPath = image.path;
        _data.primaryPhotoBytes = bytes;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking photo: $e');
    }
  }

  Future<void> pickAdditionalPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        _data.additionalPhotos.add(image.path);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking additional photo: $e');
    }
  }

  void removeAdditionalPhoto(int index) {
    if (index >= 0 && index < _data.additionalPhotos.length) {
      _data.additionalPhotos.removeAt(index);
      notifyListeners();
    }
  }

  Future<bool> startRendering() async {
    if (_isRendering) return false;
    _isRendering = true;
    _renderProgress = 0.05;
    _renderError = null;
    notifyListeners();

    // Simulated smooth progress while backend compiles video
    Timer? progressTimer;
    progressTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_renderProgress < 0.90) {
        _renderProgress += 0.05;
        notifyListeners();
      }
    });

    try {
      final result = await ApiService.instance.renderVideo(_data);
      progressTimer.cancel();

      if (result['success'] == true) {
        _renderProgress = 1.0;
        _renderedVideoUrl = result['videoUrl'];
        _renderedLocalPath = result['downloadPath'];
        _creationId = result['creationId'];
        _isRendering = false;

        // Auto-save creation to local list
        _creations.insert(
          0,
          CreationModel(
            id: _creationId ?? 'cr_${DateTime.now().millisecondsSinceEpoch}',
            title: '${_data.coupleTitle} ${_data.ceremonyTitle}',
            coupleNames: _data.coupleTitle,
            eventDate: _data.eventDate,
            venue: _data.venue,
            videoUrl: _renderedVideoUrl ?? 'assets/personalized_output.mp4',
            thumbnailUrl: _data.primaryPhotoPath ?? 'assets/candidate_chatgpt_jun.png',
            createdAt: DateTime.now(),
          ),
        );

        notifyListeners();
        return true;
      } else {
        _renderError = result['error'] ?? 'Rendering failed';
        _isRendering = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      progressTimer.cancel();
      _renderError = e.toString();
      _isRendering = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> downloadToDevice() async {
    final videoPath = _renderedVideoUrl ?? 'assets/personalized_output.mp4';
    final isAsset = videoPath.startsWith('assets/');

    return await StorageService.instance.saveVideoToDevice(
      videoSource: videoPath,
      isAsset: isAsset,
    );
  }

  Future<void> shareRenderedVideo() async {
    final videoPath = _renderedVideoUrl ?? 'assets/personalized_output.mp4';
    final isAsset = videoPath.startsWith('assets/');

    await StorageService.instance.shareVideo(
      videoSource: videoPath,
      coupleTitle: _data.coupleTitle,
      isAsset: isAsset,
    );
  }

  Future<void> loadCreations() async {
    _isLoadingCreations = true;
    notifyListeners();

    _creations = await ApiService.instance.getCreations();
    _isLoadingCreations = false;
    notifyListeners();
  }
}
