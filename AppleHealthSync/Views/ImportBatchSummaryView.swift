import SwiftUI

struct ImportBatchSummaryView: View {
    let batch: ImportBatch

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(batch.fileName)
                .font(.headline)
                .lineLimit(1)

            HStack {
                Label("\(batch.records.count)", systemImage: "number")
                if !batch.supplementalMetrics.isEmpty {
                    Label("\(batch.supplementalMetrics.count)", systemImage: "list.bullet.rectangle")
                }
                Label(batch.template.name, systemImage: "slider.horizontal.3")
                if let importedAt = batch.importedAt {
                    Label(importedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "checkmark.circle")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Import \(batch.fileName)")
    }
}
