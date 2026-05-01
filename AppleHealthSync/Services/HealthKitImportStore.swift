import Foundation
import HealthKit
import Observation

@Observable
final class HealthKitImportStore {
    private static let authorizationGrantedKey = "healthKitAuthorizationGranted"
    private let healthStore = HKHealthStore()

    var isHealthDataAvailable = HKHealthStore.isHealthDataAvailable()
    var authorizationRequested = UserDefaults.standard.bool(forKey: HealthKitImportStore.authorizationGrantedKey)
    var isImporting = false
    var importedCount = 0

    func refreshAuthorizationStatus(for templates: [ImportTemplate]) {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationRequested = false
            return
        }

        let quantityTypes = Set(templates.flatMap { template in
            template.mappings.compactMap { mapping in
                HKObjectType.quantityType(forIdentifier: mapping.metric.quantityIdentifier)
            }
        })

        let hasAuthorizedType = quantityTypes.contains { type in
            healthStore.authorizationStatus(for: type) == .sharingAuthorized
        }

        if hasAuthorizedType {
            authorizationRequested = true
            UserDefaults.standard.set(true, forKey: Self.authorizationGrantedKey)
        }
    }

    func requestAuthorization(for templates: [ImportTemplate]) async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let allMetrics = Set(templates.flatMap { $0.mappings.map(\.metric) })
        let sampleTypes = Set(allMetrics.compactMap { HKObjectType.quantityType(forIdentifier: $0.quantityIdentifier) } as [HKSampleType])
        try await healthStore.requestAuthorization(toShare: sampleTypes, read: [])
        authorizationRequested = true
        UserDefaults.standard.set(true, forKey: Self.authorizationGrantedKey)
    }

    func save(_ records: [ImportedHealthRecord]) async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        isImporting = true
        importedCount = 0
        defer { isImporting = false }

        let bloodPressureSamples = makeBloodPressureCorrelations(from: records)
        let pairedBloodPressureIDs = Set(bloodPressureSamples.flatMap(\.sourceRecordIDs))

        let quantitySamples = records.compactMap { record -> HKQuantitySample? in
            guard !pairedBloodPressureIDs.contains(record.id),
                  let type = HKObjectType.quantityType(forIdentifier: record.metric.quantityIdentifier) else {
                return nil
            }
            return makeQuantitySample(record: record, type: type)
        }

        let samples: [HKSample] = bloodPressureSamples.map(\.sample) + quantitySamples
        try await healthStore.save(samples)
        importedCount = records.count
    }

    private func makeQuantitySample(record: ImportedHealthRecord, type: HKQuantityType) -> HKQuantitySample {
        let quantity = HKQuantity(unit: record.metric.healthKitUnit, doubleValue: record.value)
        return HKQuantitySample(
            type: type,
            quantity: quantity,
            start: record.date,
            end: record.date,
            metadata: metadata(for: record)
        )
    }

    private func makeBloodPressureCorrelations(from records: [ImportedHealthRecord]) -> [BloodPressureCorrelation] {
        guard let correlationType = HKObjectType.correlationType(forIdentifier: .bloodPressure),
              let systolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureSystolic),
              let diastolicType = HKObjectType.quantityType(forIdentifier: .bloodPressureDiastolic) else {
            return []
        }

        let groupedRecords = Dictionary(grouping: records) { record in
            BloodPressureKey(date: record.date, sourceName: record.sourceName)
        }

        return groupedRecords.compactMap { _, records in
            guard let systolic = records.first(where: { $0.metric == .bloodPressureSystolic }),
                  let diastolic = records.first(where: { $0.metric == .bloodPressureDiastolic }) else {
                return nil
            }

            let systolicSample = makeQuantitySample(record: systolic, type: systolicType)
            let diastolicSample = makeQuantitySample(record: diastolic, type: diastolicType)
            let correlation = HKCorrelation(
                type: correlationType,
                start: systolic.date,
                end: systolic.date,
                objects: [systolicSample, diastolicSample],
                metadata: metadata(for: systolic)
            )
            return BloodPressureCorrelation(sample: correlation, sourceRecordIDs: [systolic.id, diastolic.id])
        }
    }

    private func metadata(for record: ImportedHealthRecord) -> [String: Any] {
        [
            HKMetadataKeyWasUserEntered: true,
            "HealtherSource": record.sourceName,
            "HealtherSourceKey": record.sourceKey
        ]
    }
}

private struct BloodPressureKey: Hashable {
    var date: Date
    var sourceName: String
}

private struct BloodPressureCorrelation {
    var sample: HKCorrelation
    var sourceRecordIDs: [UUID]
}
