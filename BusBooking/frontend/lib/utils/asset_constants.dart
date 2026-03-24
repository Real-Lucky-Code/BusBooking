/// Constants for asset paths used throughout the app
class AssetConstants {
  // Private constructor to prevent instantiation
  AssetConstants._();

  // Base paths
  static const String _imagesBase = 'assets/images';
  static const String _busesBase = '$_imagesBase/buses';
  static const String _logosBase = '$_imagesBase/logos';
  static const String _placeholdersBase = '$_imagesBase/placeholders';

  // Placeholder images
  static const String busPlaceholder = '$_placeholdersBase/bus_placeholder.png';
  static const String companyLogoPlaceholder = '$_placeholdersBase/company_logo_placeholder.png';
  static const String noImagePlaceholder = '$_placeholdersBase/no_image.png';

  // Bus type images
  static const String limousineImage = '$_busesBase/limousine.png';
  static const String sleepingBusImage = '$_busesBase/sleeping_bus.png';

  // App logo
  static const String appLogo = '$_logosBase/app_logo.png';
  static const String appIcon = '$_logosBase/app_icon.png';

  // Helper method to get bus image by type
  static String getBusImageByType(String type) {
    switch (type.toLowerCase()) {
      case 'limousine':
        return limousineImage;
      case 'giường nằm':
        return sleepingBusImage;
      default:
        return busPlaceholder;
    }
  }
}
