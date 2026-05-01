import SwiftUI
import UniformTypeIdentifiers

struct TemplateLibraryView: View {
    @Environment(ImportStore.self) private var importStore
    @Environment(TemplateExportStore.self) private var templateExportStore
    @State private var editorTemplate: ImportTemplate?
    @State private var isShowingTemplateImporter = false
    @State private var alertMessage: String?

    var body: some View {
        List {
            ForEach(importStore.templates) { template in
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        if template.isBuiltIn {
                            importStore.selectedTemplate = template
                        } else {
                            editorTemplate = template
                        }
                    } label: {
                        TemplateLibraryRow(template: template)
                    }
                    .buttonStyle(.plain)

                    if let exportURL = templateExportStore.exportURL(for: template) {
                        ShareLink(item: exportURL) {
                            Image(systemName: "square.and.arrow.up")
                                .frame(width: 34, height: 34)
                        }
                        .accessibilityLabel("Share \(template.name) template")
                    }
                }
                .swipeActions {
                    if !template.isBuiltIn {
                        Button(role: .destructive) {
                            importStore.deleteTemplate(template)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .contextMenu {
                    if let exportURL = templateExportStore.exportURL(for: template) {
                        ShareLink(item: exportURL) {
                            Label("Share Template", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isShowingTemplateImporter = true
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .accessibilityLabel("Import shared template")
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorTemplate = .blankCustom
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New template")
            }
        }
        .fileImporter(
            isPresented: $isShowingTemplateImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleTemplateImport(result)
        }
        .alert("Templates", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(item: $editorTemplate) { template in
            NavigationStack {
                TemplateEditorView(template: template)
                    .environment(importStore)
                    .environment(templateExportStore)
            }
        }
    }

    private func handleTemplateImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            try importStore.importTemplate(url: url)
            alertMessage = "Imported shared template."
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}

private struct TemplateLibraryRow: View {
    let template: ImportTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text(template.isBuiltIn ? template.format.rawValue : "Custom \(template.format.rawValue)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(template.notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(template.mappings.map { $0.metric.displayName }.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
