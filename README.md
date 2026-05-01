# Healther

Native SwiftUI iOS 26 app for importing third-party health exports into Apple Health.

## What it does

- Imports local CSV and JSON files through the iOS file picker.
- Uses premade templates for EVOLT Active, OxiPro BP2, Fitbit body metrics, Withings body exports, generic activity summaries, workout summaries, and nutrition totals.
- Lets you create custom templates that link CSV columns or JSON keys to Apple Health quantity types.
- Includes a manual import flow for one-time CSV/JSON imports or reusable templates created from the selected file.
- Exports and imports custom template JSON files so mappings can be shared.
- Maps source columns/keys to HealthKit quantity types, previews normalized records, then writes them to Apple Health.
- Saves paired systolic/diastolic blood pressure values as native HealthKit blood pressure correlations.
- Processes files locally on device. No network calls are used.

## Expected file shapes

CSV files should include a header row. JSON files can be:

```json
[
  { "date": "2026-04-30", "weight": 78.2, "bmi": 23.1, "fat": 18.5 }
]
```

or:

```json
{
  "records": [
    { "startDate": "2026-04-30T08:30:00-0700", "steps": 8200, "distance": 6200, "calories": 410 }
  ]
}
```

The mapping layer lives in `AppleHealthSync/Models/ImportTemplate.swift`.

## Custom templates

Open the template library, tap `+`, then set:

- `Date key`: CSV column or JSON key containing the date.
- `Time key`: optional separate time column/key.
- `Date formats`: one formatter per line, for example `yyyy-MM-dd HH:mm:ss`.
- `Mappings`: each source column/key linked to a HealthKit field.

## Manual imports

Open `Manual Import`, choose a CSV or JSON file, then select:

- `One-Time` to map fields and import without saving a reusable template.
- `Template` to name the mapping, preview it, save it, and share the template JSON.

Shared template JSON files can be imported from the template library.

## Build

Open `AppleHealthSync.xcodeproj` in Xcode 26 and run the `AppleHealthSync` target on an iOS 26 simulator or device. The installed app display name is Healther.

Command-line verification used here:

```sh
xcodebuild -project AppleHealthSync.xcodeproj -target AppleHealthSync -sdk iphonesimulator26.4 build
```
