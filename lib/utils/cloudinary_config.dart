// lib/utils/cloudinary_config.dart
/// Cloudinary configuration constants
///
/// To set up Cloudinary:
/// 1. Create a free account at https://cloudinary.com/
/// 2. Go to your Dashboard
/// 3. Copy your Cloud Name
/// 4. Create an upload preset:
///    - Go to Settings > Upload presets
///    - Click "Add upload preset"
///    - Set Name: "kony-app-photos"
///    - Set Mode: "Unsigned"
///    - Set Folder: "kony-app" (optional)
///    - Save
/// 5. Replace the values below with your actual values
library;

class CloudinaryConfig {
  // Replace with your actual Cloudinary cloud name
  static const String cloudName = 'duxn4ckur';

  // Replace with your actual upload preset name
  static const String uploadPreset = 'kony-app-photos';

  // Default folder structure
  static const String baseFolder = 'kony-app';

  // Image transformation presets
  static const Map<String, String> transformations = {
    'thumbnail': 'w_150,h_150,c_fill,q_auto,f_auto',
    'medium': 'w_600,h_600,c_limit,q_auto,f_auto',
    'large': 'w_1200,h_1200,c_limit,q_auto,f_auto',
  };

  /// Get the full folder path for organizing uploads
  static String getFolderPath(String reportId, String componentId) {
    return '$baseFolder/reports/$reportId/components/$componentId/photos';
  }

  /// Get optimized URL with transformations
  static String getOptimizedUrl(String originalUrl, String preset) {
    if (!transformations.containsKey(preset)) return originalUrl;

    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments.toList();

      // Find upload segment and insert transformation
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex != -1) {
        pathSegments.insert(uploadIndex + 1, transformations[preset]!);

        final newUri = uri.replace(pathSegments: pathSegments);
        return newUri.toString();
      }

      return originalUrl;
    } catch (e) {
      return originalUrl;
    }
  }
}
