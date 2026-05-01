import SwiftUI

struct ImportBatchDetailView: View {
    let batch: ImportBatch

    var body: some View {
        List {
            Section {
                ImportBatchSummaryView(batch: batch)
            }

            Section("Records") {
                ForEach(batch.records) { record in
                    RecordRow(record: record)
                }
            }

            SourceMetricsSection(metrics: batch.supplementalMetrics)
        }
        .navigationTitle(batch.fileName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
