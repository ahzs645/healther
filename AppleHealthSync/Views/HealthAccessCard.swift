import SwiftUI

struct HealthAccessCard: View {
    @Environment(ImportStore.self) private var importStore
    @Environment(HealthKitImportStore.self) private var healthKit
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health Access")
                        .font(.headline)
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button {
                Task {
                    do {
                        try await healthKit.requestAuthorization(for: importStore.templates)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Label(buttonTitle, systemImage: healthKit.authorizationRequested ? "checkmark.shield.fill" : "checkmark.shield")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!healthKit.isHealthDataAvailable || healthKit.authorizationRequested)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .alert("HealthKit", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var statusText: String {
        guard healthKit.isHealthDataAvailable else {
            return "Health data is not available on this device."
        }

        if healthKit.authorizationRequested {
            return "Access granted. Imports can be saved to Apple Health."
        }

        return "Imports are processed on device and saved to Apple Health."
    }

    private var buttonTitle: String {
        healthKit.authorizationRequested ? "Access Granted" : "Request Access"
    }
}
