import SwiftUI

struct TemplateGridView: View {
    let templates: [ImportTemplate]
    @Binding var selectedTemplate: ImportTemplate

    private let columns = [
        GridItem(.adaptive(minimum: 118), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(templates) { template in
                Button {
                    selectedTemplate = template
                } label: {
                    TemplateTileView(
                        template: template,
                        isSelected: template.id == selectedTemplate.id
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select \(template.name)")
            }
        }
        .padding(.vertical, 4)
    }
}

struct TemplateTileView: View {
    let template: ImportTemplate
    var isSelected = false

    var body: some View {
        VStack(spacing: 8) {
            LogoView(template: template)
                .frame(height: 44)

            Text(template.name)
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
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        }
    }
}

private struct LogoView: View {
    let template: ImportTemplate

    var body: some View {
        if let logoImageName = template.logoImageName,
           let image = UIImage(named: logoImageName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 4)
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: fallbackIconName)
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .frame(width: 48, height: 44)
        }
    }

    private var fallbackIconName: String {
        switch template.format {
        case .csv:
            "tablecells"
        case .json:
            "curlybraces"
        }
    }
}
