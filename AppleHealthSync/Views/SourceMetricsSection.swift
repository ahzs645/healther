import SwiftUI

struct SourceMetricsSection: View {
    let metrics: [SupplementalMetric]

    var body: some View {
        if !metrics.isEmpty {
            Section("Source Metrics") {
                ForEach(groupedMetrics, id: \.section) { group in
                    DisclosureGroup {
                        ForEach(group.metrics) { metric in
                            SupplementalMetricRow(metric: metric)
                        }
                    } label: {
                        Label(group.section, systemImage: "list.bullet.rectangle")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }

    private var groupedMetrics: [(section: String, metrics: [SupplementalMetric])] {
        Dictionary(grouping: metrics, by: \.section)
            .map { section, metrics in
                (section: section, metrics: metrics)
            }
            .sorted { lhs, rhs in
                sectionSortKey(lhs.section) < sectionSortKey(rhs.section)
            }
    }

    private func sectionSortKey(_ section: String) -> String {
        switch section {
        case "BWI Result": "00-\(section)"
        case "Summary": "01-\(section)"
        case "Body Composition": "02-\(section)"
        case "Segmental Analysis": "03-\(section)"
        default: "99-\(section)"
        }
    }
}

private struct SupplementalMetricRow: View {
    let metric: SupplementalMetric

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: metric.isHealthKitMapped ? "heart.text.square.fill" : "doc.text")
                .foregroundStyle(metric.isHealthKitMapped ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(metric.name)
                    .font(.subheadline)
                HStack(spacing: 6) {
                    Text(metric.date.formatted(date: .abbreviated, time: .shortened))
                    if metric.isHealthKitMapped {
                        Text("HealthKit")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 4) {
                Text(metric.value)
                    .font(.callout.monospacedDigit())
                if let status = metric.status {
                    Text(status)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metric.name), \(metric.value)")
    }
}
