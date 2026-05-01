import SwiftUI

struct TemplateLibraryView: View {
    @Environment(ImportStore.self) private var importStore
    @State private var editorTemplate: ImportTemplate?

    var body: some View {
        List {
            ForEach(importStore.templates) { template in
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
                .swipeActions {
                    if !template.isBuiltIn {
                        Button(role: .destructive) {
                            importStore.deleteTemplate(template)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Templates")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorTemplate = .blankCustom
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New template")
            }
        }
        .sheet(item: $editorTemplate) { template in
            NavigationStack {
                TemplateEditorView(template: template)
            }
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
