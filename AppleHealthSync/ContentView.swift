import SwiftUI

struct ContentView: View {
    @Environment(ImportStore.self) private var importStore
    @Environment(HealthKitImportStore.self) private var healthKit

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if !healthKit.authorizationRequested {
                        HealthAccessCard()
                    }

                    dashboardHeader
                    dashboardStats
                    quickActions
                    recentImports
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ImportTemplateSelectionView()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add import")
                }
            }
        }
        .task {
            healthKit.refreshAuthorizationStatus(for: importStore.templates)
        }
    }

    private var dashboardHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Healther")
                .font(.largeTitle.weight(.bold))
            Text("Review imported files, retain source metrics, and send compatible records to Apple Health.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dashboardStats: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DashboardStatCard(
                title: "Imports",
                value: "\(importStore.importHistory.count)",
                systemImage: "tray.full"
            )
            DashboardStatCard(
                title: "Health Records",
                value: "\(importedRecordCount)",
                systemImage: "heart.text.square"
            )
            DashboardStatCard(
                title: "Source Metrics",
                value: "\(supplementalMetricCount)",
                systemImage: "list.bullet.rectangle"
            )
            DashboardStatCard(
                title: "Templates",
                value: "\(importStore.templates.count)",
                systemImage: "square.grid.2x2"
            )
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Actions")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                NavigationLink {
                    ImportTemplateSelectionView()
                } label: {
                    DashboardActionRow(
                        title: "Add Import",
                        subtitle: "Choose a template, then import CSV or JSON data.",
                        systemImage: "plus.square.on.square"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    TemplateLibraryView()
                } label: {
                    DashboardActionRow(
                        title: "Manage Templates",
                        subtitle: "Edit custom import mappings and review built-in templates.",
                        systemImage: "slider.horizontal.3"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var recentImports: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Imports")
                .font(.headline)
                .foregroundStyle(.secondary)

            if importStore.importHistory.isEmpty {
                ContentUnavailableView {
                    Label("No Imports Yet", systemImage: "tray")
                } description: {
                    Text("Add an import to preview records and source metrics.")
                } actions: {
                    NavigationLink("Add Import") {
                        ImportTemplateSelectionView()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(importStore.importHistory.prefix(5)) { batch in
                        NavigationLink {
                            ImportBatchDetailView(batch: batch)
                        } label: {
                            ImportBatchSummaryView(batch: batch)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var importedRecordCount: Int {
        importStore.importHistory.reduce(0) { $0 + $1.records.count }
    }

    private var supplementalMetricCount: Int {
        importStore.importHistory.reduce(0) { $0 + $1.supplementalMetrics.count }
    }
}

private struct DashboardStatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DashboardActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    ContentView()
        .environment(ImportStore())
        .environment(HealthKitImportStore())
}
