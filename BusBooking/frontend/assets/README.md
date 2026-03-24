# Assets Directory

This directory contains all static assets used in the Bus Booking application.

## Structure

```
assets/
├── images/
│   ├── buses/           # Bus type images
│   │   ├── limousine.png
│   │   └── sleeping_bus.png
│   ├── logos/           # App and company logos
│   │   ├── app_logo.png
│   │   └── app_icon.png
│   └── placeholders/    # Placeholder images
│       ├── bus_placeholder.png
│       ├── company_logo_placeholder.png
│       └── no_image.png
```

## Usage

Import the asset constants:
```dart
import 'package:frontend/utils/asset_constants.dart';
```

Use in your widgets:
```dart
// Display bus placeholder
Image.asset(AssetConstants.busPlaceholder)

// Display specific bus type
Image.asset(AssetConstants.getBusImageByType('Limousine'))

// Display app logo
Image.asset(AssetConstants.appLogo)
```

## Adding New Images

1. Place image files in the appropriate subdirectory
2. Add the path constant to `lib/utils/asset_constants.dart`
3. Run `flutter pub get` to register the new assets

## Image Guidelines

- Use PNG format with transparency for logos and icons
- Use JPG format for photographs (bus images)
- Recommended sizes:
  - Logos: 512x512px
  - Bus images: 800x600px
  - Placeholders: 400x300px
- Optimize images before adding to reduce app size
