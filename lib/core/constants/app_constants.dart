class AppConstants {
  static const String appName = 'My Invitation';
  static const String appTagline = 'మీ ఆహ్వానాలను.. మనసులకు కలుపుతుంది';
  static const String appEnglishTagline = 'Connecting Invitations to Hearts';

  // API Endpoints
  static const String defaultApiBaseUrl = 'https://myinvitation-abun.onrender.com/api';
  static const String localHostApiBaseUrl = 'http://localhost:5000/api';

  // Supabase Configuration
  static const String supabaseUrl = 'https://fyohjrfsiftpqmjhrpjm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ5b2hqcmZzaWZ0cHFtamhycGptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQyMTUzNDcsImV4cCI6MjEwOTc5MTM0N30.swSSU9nCfVu_Z6ztib4TuHAlBSY_Cao8q-5zIMuXzNc';

  // Assets
  static const String logoAsset = 'assets/official_logo.png';
  static const String masterVideoAsset = 'assets/templates/template_01_green_screen.mp4';
  static const String sampleCouplePhoto = 'assets/templates/thumb_01_green.jpg';
  static const String renderedOutputAsset = 'assets/templates/template_01_sample_result.mp4';

  // Categories & Filters
  static const List<String> categories = [
    'Half Saree Ceremony',
    'Wedding',
    'Birthday',
    'Housewarming',
    'Engagement',
    'AI-Generated Invitations',
  ];
  static const List<String> religions = ['Hindu', 'Muslim', 'Christian'];
  static const List<String> orientations = ['16:9', '9:16'];
  static const List<String> photoFilters = ['All', 'With Photo', 'Without Photo'];
  static const List<String> occasions = [
    'All',
    'Half Saree Ceremony',
    'Wedding',
    'Birthday',
    'Housewarming',
    'Engagement',
    'AI-Generated Invitations',
  ];
}
