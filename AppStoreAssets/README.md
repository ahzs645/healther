# Healther App Store Assets

## Screenshots

Upload the JPEG files in `Screenshots/JPEG` to App Store Connect. They are exported without alpha channels.

### iPhone

- `Screenshots/JPEG/iPhone-17-Pro-01-Dashboard.jpg` - dashboard and Health access entry point, 1206 x 2622.
- `Screenshots/JPEG/iPhone-17-Pro-02-Templates.jpg` - import template grid, 1206 x 2622.
- `Screenshots/JPEG/iPhone-17-Pro-03-EVOLT-Importer.jpg` - EVOLT Active template importer, 1206 x 2622.
- `Screenshots/JPEG/iPhone-17-Pro-04-Manual-Import.jpg` - manual import start screen, 1206 x 2622.
- `Screenshots/JPEG/iPhone-17-Pro-Max-01-Dashboard.jpg` - larger iPhone dashboard, 1320 x 2868.
- `Screenshots/JPEG/iPhone-17-Pro-Max-02-Templates.jpg` - larger iPhone template grid, 1320 x 2868.

### iPad

- `Screenshots/JPEG/iPad-Pro-13-01-Dashboard.jpg` - iPad dashboard, 2064 x 2752.

## App Icon

- Final source SVG: `SourceIcon/healther-icon.svg`.
- App Store 1024 icon: `Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`.
- Bundled app icons: `../AppleHealthSync/AppIcons/HealtherIcon*.png`.

The 1024 px App Store icon has no alpha channel, which is required for App Store submission.

## Archive Notes

The current project is buildable with the generated `CFBundleIconFiles` entries in `AppleHealthSync/Info.plist`.

The asset catalog is staged here for the standard Xcode archive workflow. On a machine where Xcode's installed iOS platform/runtime versions match, you can move `Assets.xcassets` into `AppleHealthSync/Assets.xcassets` and set `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` for the target.

This local Xcode install currently reports an iOS platform/runtime mismatch for archive destinations, so the asset catalog was not wired into the target in order to keep simulator and device builds passing.
