import Foundation

struct ImportedHealthRecord: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var metric: HealthMetricKind
    var value: Double
    var sourceKey: String
    var sourceName: String

    var formattedValue: String {
        let displayValue: Double
        switch metric {
        case .bodyFatPercentage, .oxygenSaturation:
            displayValue = value * 100
        default:
            displayValue = value
        }

        let number = displayValue.formatted(.number.precision(.fractionLength(0...2)))
        return metric.displayUnit.isEmpty ? number : "\(number) \(metric.displayUnit)"
    }
}

struct SupplementalMetric: Identifiable, Codable, Hashable {
    var id = UUID()
    var date: Date
    var section: String
    var name: String
    var value: String
    var status: String?
    var isHealthKitMapped: Bool
}

struct ImportBatch: Identifiable, Codable {
    var id = UUID()
    var fileName: String
    var template: ImportTemplate
    var records: [ImportedHealthRecord]
    var supplementalMetrics: [SupplementalMetric] = []
    var importedAt: Date?
}
