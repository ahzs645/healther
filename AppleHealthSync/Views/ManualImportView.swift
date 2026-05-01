import SwiftUI
import UniformTypeIdentifiers

struct ManualImportView: View {
    @Environment(ImportStore.self) private var importStore
    @Environment(HealthKitImportStore.self) private var healthKit
    @Environment(TemplateExportStore.self) private var templateExportStore

    @State private var isShowingImporter = false
    @State private var filePreview: ImportFilePreview?
    @State private var templateName = "Custom Import"
    @State private var dateKey = ""
    @State private var timeKey: String?
    @State private var mappingRows: [ManualMappingRow] = []
    @State private var mode = ManualImportMode.oneTime
    @State private var alertMessage: String?
    @State private var activeTemplate: ImportTemplate?

    var body: some View {
        List {
            if !healthKit.authorizationRequested {
                Section {
                    HealthAccessCard()
                }
            }

            Section {
                Button {
                    isShowingImporter = true
                } label: {
                    Label(filePreview == nil ? "Choose CSV or JSON File" : "Choose Different File", systemImage: "doc.badge.plus")
                        .font(.headline)
                }

                if let filePreview {
                    LabeledContent("File", value: filePreview.fileName)
                    LabeledContent("Format", value: filePreview.format.rawValue)
                    LabeledContent("Fields", value: "\(filePreview.fields.count)")
                }
            } header: {
                Text("Source File")
            } footer: {
                Text("Manual import can be used once, or saved as a reusable template after you map the fields.")
            }

            if let filePreview {
                Section("Import Mode") {
                    Picker("Mode", selection: $mode) {
                        ForEach(ManualImportMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if mode == .saveTemplate {
                        TextField("Template name", text: $templateName)
                    }
                }

                Section("Date") {
                    Picker("Start date/time field", selection: $dateKey) {
                        ForEach(filePreview.fields) { field in
                            Text(fieldLabel(field)).tag(field.name)
                        }
                    }

                    Picker("Separate time field", selection: $timeKey) {
                        Text("None").tag(String?.none)
                        ForEach(filePreview.fields) { field in
                            Text(fieldLabel(field)).tag(String?.some(field.name))
                        }
                    }

                    Text("Date formats are tried automatically for common ISO, Apple, and US export styles.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    ForEach($mappingRows) { $row in
                        ManualMappingRowView(row: $row)
                    }
                } header: {
                    Text("Map Fields")
                } footer: {
                    Text("Leave fields set to Do Not Import when they are notes, labels, or values Apple Health cannot store.")
                }

                if !filePreview.sampleRows.isEmpty {
                    Section("Sample Rows") {
                        ForEach(Array(filePreview.sampleRows.enumerated()), id: \.offset) { index, row in
                            DisclosureGroup("Row \(index + 1)") {
                                ForEach(filePreview.fields) { field in
                                    LabeledContent(field.name, value: row[field.name] ?? "")
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        previewImport(filePreview)
                    } label: {
                        Label("Preview Import", systemImage: "doc.text.magnifyingglass")
                    }
                    .font(.headline)
                    .disabled(!canPreview)

                    if let activeTemplate, mode == .saveTemplate {
                        Button {
                            importStore.saveTemplate(activeTemplate)
                            alertMessage = "Saved \(activeTemplate.name) as a reusable template."
                        } label: {
                            Label("Save Template", systemImage: "square.and.arrow.down")
                        }

                        if let exportURL = templateExportStore.exportURL(for: activeTemplate) {
                            ShareLink(item: exportURL) {
                                Label("Share Template", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
            }

            if let batch = importStore.currentBatch,
               let activeTemplate,
               batch.template.id == activeTemplate.id {
                Section("Preview") {
                    ImportBatchSummaryView(batch: batch)

                    ForEach(batch.records.prefix(25)) { record in
                        RecordRow(record: record)
                    }

                    Button {
                        Task { await importCurrentBatch(batch) }
                    } label: {
                        if healthKit.isImporting {
                            ProgressView()
                        } else {
                            Label("Import \(batch.records.count) Records", systemImage: "heart.text.square")
                        }
                    }
                    .disabled(batch.records.isEmpty || healthKit.isImporting)
                }

                SourceMetricsSection(metrics: batch.supplementalMetrics)
            }
        }
        .navigationTitle("Manual Import")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.commaSeparatedText, .delimitedText, .text, .json],
            allowsMultipleSelection: false
        ) { result in
            handleFileResult(result)
        }
        .alert("Manual Import", isPresented: Binding(
            get: { alertMessage != nil || importStore.statusMessage != nil },
            set: { if !$0 { alertMessage = nil; importStore.statusMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(alertMessage ?? importStore.statusMessage ?? "")
        }
        .onAppear {
            healthKit.refreshAuthorizationStatus(for: importStore.templates)
        }
    }

    private var canPreview: Bool {
        !dateKey.isEmpty && !activeMappings.isEmpty && (mode == .oneTime || !templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    private var activeMappings: [ImportFieldMapping] {
        mappingRows.compactMap { row in
            guard let metric = row.metric else { return nil }
            return ImportFieldMapping(sourceKey: row.sourceKey, metric: metric)
        }
    }

    private func handleFileResult(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let preview = try ImportFileInspector.inspect(url: url)
            filePreview = preview
            templateName = defaultTemplateName(for: preview)
            dateKey = preview.suggestedDateKey
            timeKey = preview.suggestedTimeKey
            mappingRows = preview.fields
                .filter { $0.name != dateKey && $0.name != timeKey }
                .map { field in
                    ManualMappingRow(sourceKey: field.name, sampleValue: field.sampleValue, metric: suggestedMetric(for: field.name))
                }
            activeTemplate = nil
            importStore.currentBatch = nil
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func previewImport(_ preview: ImportFilePreview) {
        do {
            let template = buildTemplate(format: preview.format)
            try importStore.preview(data: preview.data, fileName: preview.fileName, template: template)
            activeTemplate = template
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func importCurrentBatch(_ batch: ImportBatch) async {
        do {
            try await healthKit.requestAuthorization(for: importStore.templates)
            try await healthKit.save(batch.records)
            importStore.markCurrentBatchImported()
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func buildTemplate(format: ImportFormat) -> ImportTemplate {
        ImportTemplate(
            id: activeTemplate?.id ?? UUID(),
            name: mode == .saveTemplate ? templateName.trimmingCharacters(in: .whitespacesAndNewlines) : "Manual Import",
            source: "Manual \(format.rawValue) import",
            format: format,
            dateKey: dateKey,
            timeKey: timeKey,
            dateFormats: [
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm",
                "yyyy-MM-dd",
                "MM/dd/yyyy HH:mm:ss",
                "MM/dd/yyyy HH:mm",
                "MM/dd/yyyy",
                "d MMMM yyyy 'at' HH:mm",
                "dd MMMM yyyy 'at' HH:mm",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            ],
            mappings: activeMappings,
            notes: mode == .saveTemplate ? "Created with Manual Import." : "One-time manual import.",
            isBuiltIn: false
        )
    }

    private func defaultTemplateName(for preview: ImportFilePreview) -> String {
        let baseName = URL(fileURLWithPath: preview.fileName).deletingPathExtension().lastPathComponent
        guard !baseName.isEmpty else { return "Custom Import" }
        return baseName
            .split { $0 == "-" || $0 == "_" || $0 == " " }
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    private func fieldLabel(_ field: ImportSourceField) -> String {
        field.sampleValue.isEmpty ? field.name : "\(field.name) - \(field.sampleValue)"
    }

    private func suggestedMetric(for sourceKey: String) -> HealthMetricKind? {
        let key = sourceKey.lowercased()
        return HealthMetricKind.allCases.first { metric in
            let name = metric.displayName.lowercased()
            return key == name || key.contains(name) || name.contains(key)
        }
    }
}

private enum ManualImportMode: String, CaseIterable, Identifiable {
    case oneTime
    case saveTemplate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneTime: "One-Time"
        case .saveTemplate: "Template"
        }
    }
}

private struct ManualMappingRow: Identifiable, Hashable {
    var id = UUID()
    var sourceKey: String
    var sampleValue: String
    var metric: HealthMetricKind?
}

private struct ManualMappingRowView: View {
    @Binding var row: ManualMappingRow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(row.sourceKey)
                    .font(.headline)
                if !row.sampleValue.isEmpty {
                    Text(row.sampleValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Picker("Health field", selection: $row.metric) {
                Text("Do Not Import").tag(HealthMetricKind?.none)
                ForEach(HealthMetricKind.allCases) { metric in
                    Text(metric.displayNameWithUnit).tag(HealthMetricKind?.some(metric))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private extension HealthMetricKind {
    var displayNameWithUnit: String {
        displayUnit.isEmpty ? displayName : "\(displayName) (\(displayUnit))"
    }
}

#Preview {
    NavigationStack {
        ManualImportView()
            .environment(ImportStore())
            .environment(HealthKitImportStore())
            .environment(TemplateExportStore())
    }
}
