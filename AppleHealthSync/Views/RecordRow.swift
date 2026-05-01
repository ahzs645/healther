import SwiftUI

struct RecordRow: View {
    let record: ImportedHealthRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(record.metric.displayName)
                    .font(.subheadline.weight(.semibold))
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(record.formattedValue)
                .font(.callout.monospacedDigit())
        }
    }

    private var iconName: String {
        switch record.metric {
        case .bloodPressureSystolic, .bloodPressureDiastolic, .heartRate:
            "waveform.path.ecg"
        case .bodyMass, .leanBodyMass, .bodyMassIndex, .bodyFatPercentage:
            "figure"
        case .stepCount, .distanceWalkingRunning, .activeEnergyBurned, .basalEnergyBurned:
            "figure.walk"
        case .oxygenSaturation:
            "lungs"
        case .dietaryWater:
            "drop"
        case .dietaryCaffeine, .dietaryProtein, .dietaryCarbohydrates, .dietaryFatTotal:
            "fork.knife"
        }
    }
}
