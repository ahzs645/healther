import SwiftUI

struct ImportTemplateSelectionView: View {
    @Environment(ImportStore.self) private var importStore

    private let columns = [
        GridItem(.adaptive(minimum: 142), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add Import")
                        .font(.largeTitle.weight(.bold))
                    Text("Select the source format that matches your export.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(importStore.templates) { template in
                        NavigationLink {
                            ImportTemplateImportView(template: template)
                        } label: {
                            TemplateTileView(template: template)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Import from \(template.name)")
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Add Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    TemplateLibraryView()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Manage templates")
            }
        }
    }
}

#Preview {
    NavigationStack {
        ImportTemplateSelectionView()
            .environment(ImportStore())
            .environment(HealthKitImportStore())
    }
}
