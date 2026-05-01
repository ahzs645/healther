import SwiftUI

@main
struct AppleHealthSyncApp: App {
    @State private var importStore = ImportStore()
    @State private var healthStore = HealthKitImportStore()
    @State private var templateExportStore = TemplateExportStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(importStore)
                .environment(healthStore)
                .environment(templateExportStore)
                .task {
                    loadRequestedSampleIfNeeded()
                }
        }
    }

    private func loadRequestedSampleIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flagIndex = arguments.firstIndex(where: { $0 == "-HealtherLoadSample" || $0 == "-AppleHealthSyncLoadSample" }),
              arguments.indices.contains(flagIndex + 1) else {
            return
        }

        try? importStore.loadBundledSample(named: arguments[flagIndex + 1])
    }
}
