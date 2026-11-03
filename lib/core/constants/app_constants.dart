class AppConstants {
  static const String appName = 'My Invitation';
  static const String appTagline = 'Royal Video Invitation Maker';

  // API Endpoints
  // Default to localhost for Android emulator / local testing (10.0.2.2 or localhost)
  static const String defaultApiBaseUrl = 'http://10.0.2.2:5000/api';
  static const String localHostApiBaseUrl = 'http://localhost:5000/api';

  // Assets
  static const String logoAsset = 'assets/my_invitation_logo.png';
  static const String masterVideoAsset = 'assets/wedding_template_master.mp4';
  static const String sampleCouplePhoto = 'assets/candidate_chatgpt_jun.png';
  static const String renderedOutputAsset = 'assets/personalized_output.mp4';

  // Categories & Filters
  static const List<String> religions = ['All', 'Hindu', 'Christian', 'Muslim'];
  static const List<String> orientations = ['All', '9:16', '16:9'];
  static const List<String> photoFilters = ['All', 'With Photo', 'Without Photo'];
  static const List<String> occasions = ['All', 'Wedding', 'Reception', 'Engagement', 'Sangeet'];
}
