import Foundation
import Observation

@Observable
final class ImportStore {
    private static let customTemplatesKey = "customImportTemplates"
    private static let importHistoryKey = "importHistory"

    var templates = ImportTemplate.builtIns
    var selectedTemplate = ImportTemplate.builtIns[0]
    var currentBatch: ImportBatch?
    var importHistory: [ImportBatch] = []
    var statusMessage: String?

    init() {
        loadCustomTemplates()
        loadImportHistory()
    }

    func selectTemplate(_ template: ImportTemplate) {
        selectedTemplate = template
        if currentBatch?.template.id != template.id {
            currentBatch = nil
        }
    }

    func loadFile(url: URL) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let records = try ImportParser.parse(data: data, template: selectedTemplate)
        let supplementalMetrics = try ImportParser.supplementalMetrics(data: data, template: selectedTemplate)
        currentBatch = ImportBatch(
            fileName: url.lastPathComponent,
            template: selectedTemplate,
            records: records,
            supplementalMetrics: supplementalMetrics,
            importedAt: nil
        )
        statusMessage = records.isEmpty ? "No importable records found." : nil
    }

    func preview(data: Data, fileName: String, template: ImportTemplate) throws {
        selectedTemplate = template
        let records = try ImportParser.parse(data: data, template: template)
        let supplementalMetrics = try ImportParser.supplementalMetrics(data: data, template: template)
        currentBatch = ImportBatch(
            fileName: fileName,
            template: template,
            records: records,
            supplementalMetrics: supplementalMetrics,
            importedAt: nil
        )
        statusMessage = records.isEmpty ? "No importable records found." : nil
    }

    func loadBundledSample(named sampleName: String) throws {
        let sample = sampleName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let fixture = SampleFixture.allCases.first(where: { $0.rawValue == sample || $0.fileName == sample }),
              let url = Bundle.main.url(forResource: fixture.resourceName, withExtension: fixture.fileExtension, subdirectory: "SampleData")
                ?? Bundle.main.url(forResource: fixture.resourceName, withExtension: fixture.fileExtension) else {
            throw ImportStoreError.missingSample(sampleName)
        }

        selectedTemplate = fixture.template
        let data = try Data(contentsOf: url)
        let records = try ImportParser.parse(data: data, template: fixture.template)
        let supplementalMetrics = try ImportParser.supplementalMetrics(data: data, template: fixture.template)
        currentBatch = ImportBatch(
            fileName: fixture.fileName,
            template: fixture.template,
            records: records,
            supplementalMetrics: supplementalMetrics,
            importedAt: nil
        )
        statusMessage = records.isEmpty ? "No importable records found." : nil
    }

    func markCurrentBatchImported() {
        guard var batch = currentBatch else { return }
        batch.importedAt = Date()
        importHistory.insert(batch, at: 0)
        importHistory = Array(importHistory.prefix(50))
        currentBatch = nil
        statusMessage = nil
        persistImportHistory()
    }

    func saveTemplate(_ template: ImportTemplate) {
        var updatedTemplate = template
        updatedTemplate.isBuiltIn = false

        if let index = templates.firstIndex(where: { $0.id == updatedTemplate.id }) {
            templates[index] = updatedTemplate
        } else {
            templates.append(updatedTemplate)
        }

        selectedTemplate = updatedTemplate
        persistCustomTemplates()
    }

    func deleteTemplate(_ template: ImportTemplate) {
        guard !template.isBuiltIn else { return }
        templates.removeAll { $0.id == template.id }
        if selectedTemplate.id == template.id {
            selectedTemplate = templates.first ?? ImportTemplate.builtIns[0]
        }
        persistCustomTemplates()
    }

    func importTemplate(url: URL) throws {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        var template = try JSONDecoder().decode(ImportTemplate.self, from: data)
        template.id = UUID()
        template.isBuiltIn = false
        template.logoImageName = nil
        saveTemplate(template)
    }

    private func loadCustomTemplates() {
        guard let data = UserDefaults.standard.data(forKey: Self.customTemplatesKey),
              let customTemplates = try? JSONDecoder().decode([ImportTemplate].self, from: data) else {
            templates = ImportTemplate.builtIns
            selectedTemplate = templates[0]
            return
        }

        templates = ImportTemplate.builtIns + customTemplates
        selectedTemplate = templates[0]
    }

    private func persistCustomTemplates() {
        let customTemplates = templates.filter { !$0.isBuiltIn }
        guard let data = try? JSONEncoder().encode(customTemplates) else { return }
        UserDefaults.standard.set(data, forKey: Self.customTemplatesKey)
    }

    private func loadImportHistory() {
        guard let data = UserDefaults.standard.data(forKey: Self.importHistoryKey),
              let history = try? JSONDecoder().decode([ImportBatch].self, from: data) else {
            importHistory = []
            return
        }

        importHistory = history
    }

    private func persistImportHistory() {
        guard let data = try? JSONEncoder().encode(importHistory) else { return }
        UserDefaults.standard.set(data, forKey: Self.importHistoryKey)
    }
}

enum ImportStoreError: LocalizedError {
    case missingSample(String)

    var errorDescription: String? {
        switch self {
        case .missingSample(let name):
            "Missing bundled sample named \(name)."
        }
    }
}

enum SampleFixture: String, CaseIterable {
    case evoltActive = "evolt"
    case oxiPro = "oxipro"
    case fitbitBody = "fitbit-body"
    case dailyActivity = "daily-activity"

    var fileName: String {
        switch self {
        case .evoltActive: "evolt-all-scans.json"
        case .oxiPro: "oxipro-bp2.csv"
        case .fitbitBody: "fitbit-body.json"
        case .dailyActivity: "daily-activity.csv"
        }
    }

    var resourceName: String {
        URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
    }

    var fileExtension: String {
        URL(fileURLWithPath: fileName).pathExtension
    }

    var template: ImportTemplate {
        switch self {
        case .evoltActive:
            ImportTemplate.builtIns.first { $0.name == "EVOLT Active" }!
        case .oxiPro:
            ImportTemplate.builtIns.first { $0.name == "OxiPro BP2" }!
        case .fitbitBody:
            ImportTemplate.builtIns.first { $0.name == "Fitbit Body Metrics JSON" }!
        case .dailyActivity:
            ImportTemplate.builtIns.first { $0.name == "Daily Activity CSV" }!
        }
    }
}
