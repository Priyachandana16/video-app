import 'package:flutter/material.dart';
import '../models/template_model.dart';
import '../services/api_service.dart';

class TemplateProvider extends ChangeNotifier {
  List<TemplateModel> _templates = [];
  bool _isLoading = false;
  TemplateModel? _selectedTemplate;

  // Filters
  String _selectedReligion = 'All';
  String _selectedOrientation = 'All';
  String _selectedPhotoFilter = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<TemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;
  TemplateModel? get selectedTemplate => _selectedTemplate;

  String get selectedReligion => _selectedReligion;
  String get selectedOrientation => _selectedOrientation;
  String get selectedPhotoFilter => _selectedPhotoFilter;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  bool get hasActiveFilters =>
      _selectedReligion != 'All' ||
      _selectedOrientation != 'All' ||
      _selectedPhotoFilter != 'All' ||
      _selectedCategory != 'All';

  TemplateProvider() {
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    _isLoading = true;
    notifyListeners();

    bool? hasPhoto;
    if (_selectedPhotoFilter == 'With Photo') hasPhoto = true;
    if (_selectedPhotoFilter == 'Without Photo') hasPhoto = false;

    _templates = await ApiService.instance.getTemplates(
      religion: _selectedReligion,
      orientation: _selectedOrientation,
      hasPhoto: hasPhoto,
      category: _selectedCategory,
    );

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      _templates = _templates.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.religion.toLowerCase().contains(q);
      }).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectTemplate(TemplateModel template) {
    _selectedTemplate = template;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadTemplates();
  }

  void setReligion(String religion) {
    _selectedReligion = religion;
    loadTemplates();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    loadTemplates();
  }

  void setPhotoFilter(String filter) {
    if (_selectedPhotoFilter == filter) {
      _selectedPhotoFilter = 'All';
    } else {
      _selectedPhotoFilter = filter;
    }
    loadTemplates();
  }

  void applyFilters({
    required String religion,
    required String orientation,
    required String photoFilter,
  }) {
    _selectedReligion = religion;
    _selectedOrientation = orientation;
    _selectedPhotoFilter = photoFilter;
    loadTemplates();
  }

  void resetFilters() {
    _selectedReligion = 'All';
    _selectedOrientation = 'All';
    _selectedPhotoFilter = 'All';
    _selectedCategory = 'All';
    _searchQuery = '';
    loadTemplates();
  }
}
