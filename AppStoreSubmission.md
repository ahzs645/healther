# Healther App Store Submission Notes

## Configured

- App display name: Healther.
- Bundle identifier: `com.ahmadjalil.healther`.
- Version: `1.1`, build `1`.
- HealthKit entitlement and HealthKit usage descriptions.
- CSV and JSON document type support.
- Temporary app icon asset catalog staged in `AppStoreAssets/Assets.xcassets`.
- Healther icon source stored at `AppStoreAssets/SourceIcon/healther-icon.svg`.
- Bundled icon PNGs generated under `AppleHealthSync/AppIcons` and referenced from `Info.plist`.
- Privacy manifest with tracking disabled and UserDefaults required-reason API declared.
- Export compliance flag set to no non-exempt encryption.

## Before Submission

- Replace `AppStoreAssets/SourceIcon/healther-icon.svg` and regenerate `AppStoreAssets/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` plus `AppleHealthSync/AppIcons/HealtherIcon*.png` when the final logo changes.
- Before archiving, move `AppStoreAssets/Assets.xcassets` into `AppleHealthSync/Assets.xcassets` and set `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` for Debug and Release in the target build settings. This was left outside the target because the current local Xcode install reports an asset-catalog runtime mismatch: installed simulator runtimes `23C54`/`23E244` do not match the iOS 26.4 SDK build `23E252`.
- Confirm `com.ahmadjalil.healther` is the desired App Store Connect bundle ID. If your Apple Developer account uses a company domain, update it before creating the App Store record.
- Add a privacy policy URL in App Store Connect.
- In App Store Connect privacy answers, use Data Not Collected if health files remain on-device and are not transmitted to you or third parties.
- Prepare App Store screenshots for iPhone and iPad.
- Prepare review notes that explain HealthKit access is used to save user-selected imports into Apple Health.
