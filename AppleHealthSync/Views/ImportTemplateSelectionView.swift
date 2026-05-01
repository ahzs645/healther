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
                    NavigationLink {
                        ManualImportView()
                    } label: {
                        ManualImportTileView()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Manual import")

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

private struct ManualImportTileView: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: "wand.and.sparkles")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .frame(width: 48, height: 44)

            Text("Manual Import")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(minHeight: 32, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: 106)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ImportTemplateSelectionView()
            .environment(ImportStore())
            .environment(HealthKitImportStore())
            .environment(TemplateExportStore())
    }
}
