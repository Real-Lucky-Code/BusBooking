import 'package:flutter/material.dart';
import 'package:frontend/utils/asset_constants.dart';

/// Widget helper for displaying images with proper fallbacks
class AppImage extends StatelessWidget {
  final String? imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? fallbackAsset;

  const AppImage({
    super.key,
    this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackAsset,
  });

  /// Display bus image from network URL or asset
  factory AppImage.bus({
    String? imageUrl,
    String? busType,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return AppImage(
      imageUrl: imageUrl,
      assetPath: busType != null ? AssetConstants.getBusImageByType(busType) : null,
      width: width,
      height: height,
      fit: fit,
      fallbackAsset: AssetConstants.busPlaceholder,
    );
  }

  /// Display company logo from network URL or asset
  factory AppImage.companyLogo({
    String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return AppImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fallbackAsset: AssetConstants.companyLogoPlaceholder,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Priority: network URL > asset path > fallback asset > default placeholder
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoading(loadingProgress);
        },
      );
    }

    if (assetPath != null && assetPath!.isNotEmpty) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    final asset = fallbackAsset ?? AssetConstants.noImagePlaceholder;
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _buildDefaultPlaceholder(),
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 48,
      ),
    );
  }

  Widget _buildLoading(ImageChunkEvent loadingProgress) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
        ),
      ),
    );
  }
}
