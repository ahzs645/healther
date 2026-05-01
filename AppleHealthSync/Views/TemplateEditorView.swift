import SwiftUI

struct TemplateEditorView: View {
    @Environment(ImportStore.self) private var importStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ImportTemplate
    @State private var dateFormatsText: String

    init(template: ImportTemplate) {
        _draft = State(initialValue: template)
        _dateFormatsText = State(initialValue: template.dateFormats.joined(separator: "\n"))
    }

    var body: some View {
        Form {
            Section("Source") {
                TextField("Name", text: $draft.name)
                TextField("Source", text: $draft.source)
                Picker("Format", selection: $draft.format) {
                    ForEach(ImportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                TextField("Notes", text: $draft.notes, axis: .vertical)
            }

            Section("Date") {
                TextField("Date key", text: $draft.dateKey)
                OptionalTextField("Time key", text: $draft.timeKey)
                TextField("Date formats", text: $dateFormatsText, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Mappings") {
                ForEach($draft.mappings) { $mapping in
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Source column or JSON key", text: $mapping.sourceKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        Picker("Health field", selection: $mapping.metric) {
                            ForEach(HealthMetricKind.allCases) { metric in
                                Text(metric.displayName).tag(metric)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    draft.mappings.remove(atOffsets: indexSet)
                }

                Button {
                    draft.mappings.append(ImportFieldMapping(sourceKey: "", metric: .bodyMass))
                } label: {
                    Label("Add Mapping", systemImage: "plus.circle")
                }
            }
        }
        .navigationTitle(draft.name.isEmpty ? "Template" : draft.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var template = draft
                    template.dateFormats = dateFormatsText
                        .split(whereSeparator: \.isNewline)
                        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty }
                    importStore.saveTemplate(template)
                    dismiss()
                }
                .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.mappings.isEmpty)
            }
        }
    }
}

private struct OptionalTextField: View {
    let title: String
    @Binding var text: String?

    init(_ title: String, text: Binding<String?>) {
        self.title = title
        _text = text
    }

    var body: some View {
        TextField(title, text: Binding(
            get: { text ?? "" },
            set: { text = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
        ))
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }
}
