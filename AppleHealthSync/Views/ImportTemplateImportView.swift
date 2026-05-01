import SwiftUI
import UniformTypeIdentifiers

struct ImportTemplateImportView: View {
    @Environment(ImportStore.self) private var importStore
    @Environment(HealthKitImportStore.self) private var healthKit

    let template: ImportTemplate

    @State private var isShowingImporter = false
    @State private var alertMessage: String?

    var body: some View {
        List {
            if !healthKit.authorizationRequested {
                Section {
                    HealthAccessCard()
                }
            }

            Section("Template") {
                HStack(spacing: 12) {
                    TemplateTileView(template: template, isSelected: true)
                        .frame(width: 132)
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.source)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(template.notes)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                TemplateDetailView(template: template)
            }

            Section {
                Button {
                    isShowingImporter = true
                } label: {
                    Label("Choose \(template.format.rawValue) File", systemImage: "doc.badge.plus")
                }
                .font(.headline)

                Button {
                    loadSample()
                } label: {
                    Label("Load Matching Sample", systemImage: "shippingbox")
                }
                .disabled(sampleName == nil)
            }

            if let batch = importStore.currentBatch, batch.template.id == template.id {
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
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            handleImportResult(result)
        }
        .alert("Import", isPresented: Binding(
            get: { alertMessage != nil || importStore.statusMessage != nil },
            set: { if !$0 { alertMessage = nil; importStore.statusMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(alertMessage ?? importStore.statusMessage ?? "")
        }
        .onAppear {
            importStore.selectTemplate(template)
            healthKit.refreshAuthorizationStatus(for: importStore.templates)
        }
    }

    private var allowedTypes: [UTType] {
        switch template.format {
        case .csv:
            [.commaSeparatedText, .delimitedText, .text]
        case .json:
            [.json]
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        do {
            importStore.selectTemplate(template)
            guard let url = try result.get().first else { return }
            try importStore.loadFile(url: url)
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

    private var sampleName: String? {
        switch template.name {
        case "EVOLT Active":
            "evolt"
        case "OxiPro BP2":
            "oxipro"
        case "Fitbit Body Metrics JSON":
            "fitbit-body"
        case "Daily Activity CSV":
            "daily-activity"
        default:
            nil
        }
    }

    private func loadSample() {
        guard let sampleName else { return }
        do {
            importStore.selectTemplate(template)
            try importStore.loadBundledSample(named: sampleName)
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
