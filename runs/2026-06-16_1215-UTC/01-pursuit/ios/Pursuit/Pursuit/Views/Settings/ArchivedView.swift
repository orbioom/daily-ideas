import SwiftUI
import SwiftData

struct ArchivedView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @Query(sort: [SortDescriptor(\Application.dateAdded, order: .reverse)])
    private var applications: [Application]

    private var archived: [Application] { applications.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if archived.isEmpty {
                    EmptyStateView(symbol: "archivebox",
                                   title: "Nothing archived",
                                   message: "Applications you archive from the pipeline will be kept here.")
                } else {
                    List {
                        ForEach(archived) { app in
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.role).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                                    Text(app.company).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                                }
                                Spacer()
                                StatusBadge(status: app.status, compact: true)
                            }
                            .listRowBackground(Theme.surface)
                            .swipeActions(edge: .trailing) {
                                Button { unarchive(app) } label: { Label("Restore", systemImage: "tray.and.arrow.up") }
                                    .tint(Theme.accent)
                                Button(role: .destructive) { delete(app) } label: { Label("Delete", systemImage: "trash") }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Archived")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
        }
    }

    private func unarchive(_ app: Application) {
        app.isArchived = false
        try? context.save()
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
    }

    private func delete(_ app: Application) {
        context.delete(app)
        try? context.save()
        Haptics.notify(.warning, enabled: settings.hapticsEnabled)
    }
}
