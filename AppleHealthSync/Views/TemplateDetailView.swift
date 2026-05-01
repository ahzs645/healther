import SwiftUI

struct TemplateDetailView: View {
    let template: ImportTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledContent("Source", value: template.source)
            LabeledContent("Format", value: template.format.rawValue)
            LabeledContent("Date field", value: template.dateKey)

            if let timeKey = template.timeKey {
                LabeledContent("Time field", value: timeKey)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Mapped fields")
                    .font(.subheadline.weight(.semibold))
                ForEach(template.mappings) { mapping in
                    HStack {
                        Text(mapping.sourceKey)
                            .font(.callout.monospaced())
                        Spacer()
                        Text(mapping.metric.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
