import Foundation
import HealthKit

enum ImportFormat: String, CaseIterable, Identifiable, Codable {
    case csv = "CSV"
    case json = "JSON"

    var id: String { rawValue }
}

enum HealthMetricKind: String, CaseIterable, Codable, Identifiable {
    case bloodPressureSystolic
    case bloodPressureDiastolic
    case heartRate
    case bodyMass
    case leanBodyMass
    case bodyMassIndex
    case bodyFatPercentage
    case stepCount
    case activeEnergyBurned
    case basalEnergyBurned
    case distanceWalkingRunning
    case oxygenSaturation
    case dietaryWater
    case dietaryCaffeine
    case dietaryProtein
    case dietaryCarbohydrates
    case dietaryFatTotal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bloodPressureSystolic: "Systolic"
        case .bloodPressureDiastolic: "Diastolic"
        case .heartRate: "Heart rate"
        case .bodyMass: "Weight"
        case .leanBodyMass: "Lean body mass"
        case .bodyMassIndex: "BMI"
        case .bodyFatPercentage: "Body fat"
        case .stepCount: "Steps"
        case .activeEnergyBurned: "Active energy"
        case .basalEnergyBurned: "Basal energy"
        case .distanceWalkingRunning: "Walking/running distance"
        case .oxygenSaturation: "Oxygen saturation"
        case .dietaryWater: "Water"
        case .dietaryCaffeine: "Caffeine"
        case .dietaryProtein: "Protein"
        case .dietaryCarbohydrates: "Carbohydrates"
        case .dietaryFatTotal: "Fat"
        }
    }

    var quantityIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .bloodPressureSystolic: .bloodPressureSystolic
        case .bloodPressureDiastolic: .bloodPressureDiastolic
        case .heartRate: .heartRate
        case .bodyMass: .bodyMass
        case .leanBodyMass: .leanBodyMass
        case .bodyMassIndex: .bodyMassIndex
        case .bodyFatPercentage: .bodyFatPercentage
        case .stepCount: .stepCount
        case .activeEnergyBurned: .activeEnergyBurned
        case .basalEnergyBurned: .basalEnergyBurned
        case .distanceWalkingRunning: .distanceWalkingRunning
        case .oxygenSaturation: .oxygenSaturation
        case .dietaryWater: .dietaryWater
        case .dietaryCaffeine: .dietaryCaffeine
        case .dietaryProtein: .dietaryProtein
        case .dietaryCarbohydrates: .dietaryCarbohydrates
        case .dietaryFatTotal: .dietaryFatTotal
        }
    }

    var healthKitUnit: HKUnit {
        switch self {
        case .bloodPressureSystolic, .bloodPressureDiastolic: .millimeterOfMercury()
        case .heartRate: .count().unitDivided(by: .minute())
        case .bodyMass, .leanBodyMass: .gramUnit(with: .kilo)
        case .bodyMassIndex, .stepCount: .count()
        case .bodyFatPercentage, .oxygenSaturation: .percent()
        case .activeEnergyBurned, .basalEnergyBurned: .kilocalorie()
        case .distanceWalkingRunning: .meter()
        case .dietaryWater: .liter()
        case .dietaryCaffeine, .dietaryProtein, .dietaryCarbohydrates, .dietaryFatTotal: .gram()
        }
    }

    var displayUnit: String {
        switch self {
        case .bloodPressureSystolic, .bloodPressureDiastolic: "mmHg"
        case .heartRate: "bpm"
        case .bodyMass, .leanBodyMass: "kg"
        case .bodyMassIndex, .stepCount: ""
        case .bodyFatPercentage, .oxygenSaturation: "%"
        case .activeEnergyBurned, .basalEnergyBurned: "kcal"
        case .distanceWalkingRunning: "m"
        case .dietaryWater: "L"
        case .dietaryCaffeine, .dietaryProtein, .dietaryCarbohydrates, .dietaryFatTotal: "g"
        }
    }

    nonisolated func normalizedHealthKitValue(from importedValue: Double) -> Double {
        switch self {
        case .bodyFatPercentage, .oxygenSaturation:
            importedValue > 1 ? importedValue / 100 : importedValue
        default:
            importedValue
        }
    }
}

struct ImportFieldMapping: Identifiable, Codable, Hashable {
    var id = UUID()
    var sourceKey: String
    var metric: HealthMetricKind
}

struct ImportTemplate: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var source: String
    var format: ImportFormat
    var dateKey: String
    var timeKey: String?
    var dateFormats: [String]
    var mappings: [ImportFieldMapping]
    var notes: String
    var isBuiltIn = true
    var logoImageName: String?

    static let builtIns: [ImportTemplate] = [
        ImportTemplate(
            name: "EVOLT Active",
            source: "EVOLT Active all scans JSON",
            format: .json,
            dateKey: "scanDate",
            timeKey: nil,
            dateFormats: ["d MMMM yyyy 'at' HH:mm", "dd MMMM yyyy 'at' HH:mm", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"],
            mappings: [
                ImportFieldMapping(sourceKey: "Total Body Weight", metric: .bodyMass),
                ImportFieldMapping(sourceKey: "Lean Body Mass", metric: .leanBodyMass),
                ImportFieldMapping(sourceKey: "Total Body Fat Percentage", metric: .bodyFatPercentage),
                ImportFieldMapping(sourceKey: "Basal Metabolic Rate (BMR)", metric: .basalEnergyBurned)
            ],
            notes: "Imports EVOLT body composition scans exported from EVOLT Active.",
            logoImageName: "evolt-active"
        ),
        ImportTemplate(
            name: "OxiPro BP2",
            source: "Health Diary by MedM CSV",
            format: .csv,
            dateKey: "Date",
            timeKey: "Time",
            dateFormats: ["yyyy-MM-dd HH:mm", "yyyy-MM-dd h:mm a", "yyyy-MM-dd"],
            mappings: [
                ImportFieldMapping(sourceKey: "Sys", metric: .bloodPressureSystolic),
                ImportFieldMapping(sourceKey: "Dia", metric: .bloodPressureDiastolic),
                ImportFieldMapping(sourceKey: "Pulse", metric: .heartRate)
            ],
            notes: "Matches the OxiPro BP2 export used by the sample app.",
            logoImageName: "oxipro"
        ),
        ImportTemplate(
            name: "Fitbit Body Metrics",
            source: "Fitbit archive CSV",
            format: .csv,
            dateKey: "date",
            timeKey: nil,
            dateFormats: ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd", "MM/dd/yyyy"],
            mappings: [
                ImportFieldMapping(sourceKey: "weight", metric: .bodyMass),
                ImportFieldMapping(sourceKey: "bmi", metric: .bodyMassIndex),
                ImportFieldMapping(sourceKey: "fat", metric: .bodyFatPercentage)
            ],
            notes: "Imports weight, BMI, and body fat columns from a Fitbit export.",
            logoImageName: "fitbit"
        ),
        ImportTemplate(
            name: "Fitbit Body Metrics JSON",
            source: "Fitbit archive JSON",
            format: .json,
            dateKey: "date",
            timeKey: nil,
            dateFormats: ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd", "MM/dd/yyyy"],
            mappings: [
                ImportFieldMapping(sourceKey: "weight", metric: .bodyMass),
                ImportFieldMapping(sourceKey: "bmi", metric: .bodyMassIndex),
                ImportFieldMapping(sourceKey: "fat", metric: .bodyFatPercentage)
            ],
            notes: "Reads either a JSON array or a top-level data/records array.",
            logoImageName: "fitbit"
        ),
        ImportTemplate(
            name: "Withings Body CSV",
            source: "Withings export",
            format: .csv,
            dateKey: "Date",
            timeKey: nil,
            dateFormats: ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd", "MM/dd/yyyy HH:mm:ss"],
            mappings: [
                ImportFieldMapping(sourceKey: "Weight", metric: .bodyMass),
                ImportFieldMapping(sourceKey: "Fat Mass %", metric: .bodyFatPercentage),
                ImportFieldMapping(sourceKey: "Heart Pulse", metric: .heartRate)
            ],
            notes: "Maps common Withings scale export columns into HealthKit quantities.",
            logoImageName: "withings"
        ),
        ImportTemplate(
            name: "Daily Activity CSV",
            source: "Garmin, Fitbit, or generic activity summaries",
            format: .csv,
            dateKey: "date",
            timeKey: nil,
            dateFormats: ["yyyy-MM-dd", "MM/dd/yyyy"],
            mappings: [
                ImportFieldMapping(sourceKey: "steps", metric: .stepCount),
                ImportFieldMapping(sourceKey: "distance_m", metric: .distanceWalkingRunning),
                ImportFieldMapping(sourceKey: "active_kcal", metric: .activeEnergyBurned)
            ],
            notes: "Imports daily steps, distance, and active calories from plain exports.",
            logoImageName: "garmin"
        ),
        ImportTemplate(
            name: "Workout Summary",
            source: "Generic JSON or CSV",
            format: .json,
            dateKey: "startDate",
            timeKey: nil,
            dateFormats: ["yyyy-MM-dd'T'HH:mm:ssZ", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"],
            mappings: [
                ImportFieldMapping(sourceKey: "distance", metric: .distanceWalkingRunning),
                ImportFieldMapping(sourceKey: "calories", metric: .activeEnergyBurned),
                ImportFieldMapping(sourceKey: "steps", metric: .stepCount)
            ],
            notes: "Useful for exported activity summaries when workout details are not available."
        ),
        ImportTemplate(
            name: "Nutrition Daily Totals",
            source: "Generic nutrition CSV/JSON",
            format: .csv,
            dateKey: "date",
            timeKey: nil,
            dateFormats: ["yyyy-MM-dd", "MM/dd/yyyy"],
            mappings: [
                ImportFieldMapping(sourceKey: "water_l", metric: .dietaryWater),
                ImportFieldMapping(sourceKey: "caffeine_g", metric: .dietaryCaffeine),
                ImportFieldMapping(sourceKey: "protein_g", metric: .dietaryProtein),
                ImportFieldMapping(sourceKey: "carbs_g", metric: .dietaryCarbohydrates),
                ImportFieldMapping(sourceKey: "fat_g", metric: .dietaryFatTotal)
            ],
            notes: "Imports common daily nutrition totals into Apple Health."
        )
    ]
}

extension ImportTemplate {
    static var blankCustom: ImportTemplate {
        ImportTemplate(
            name: "Custom Import",
            source: "Custom file",
            format: .csv,
            dateKey: "date",
            timeKey: nil,
            dateFormats: ["yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ssZ"],
            mappings: [
                ImportFieldMapping(sourceKey: "value", metric: .bodyMass)
            ],
            notes: "Custom template",
            isBuiltIn: false
        )
    }
}
