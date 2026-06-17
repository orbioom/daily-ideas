import SwiftUI
import SwiftData

/// All cooks: active, planned and the full history. Entry point to the New Cook flow.
struct CooksScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Cook.createdAt, order: .reverse) private var cooks: [Cook]

    @State private var showingNew = false

    private var active: [Cook] { cooks.filter { $0.status.isActive } }
    private var planned: [Cook] { cooks.filter { $0.status == .planned } }
    private var done: [Cook] { cooks.filter { $0.status == .done } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Cooks")
            .navigationDestination(for: Cook.self) { CookDetailView(cook: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: {
                        Label("New Cook", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) { NewCookView() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if cooks.isEmpty {
            EmptyStateView(symbol: "list.bullet.rectangle",
                           title: "No cooks yet",
                           message: "Plan or start your first cook and it'll show up here.",
                           actionTitle: "New Cook") { showingNew = true }
        } else {
            List {
                section("Active", active)
                section("Planned", planned)
                section("History", done)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [Cook]) -> some View {
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { cook in
                    NavigationLink(value: cook) { CookRow(cook: cook) }
                        .listRowBackground(Theme.surface)
                }
                .onDelete { offsets in delete(items, offsets) }
            }
        }
    }

    private func delete(_ items: [Cook], _ offsets: IndexSet) {
        for index in offsets {
            if let cook = items[safe: index] {
                context.delete(cook)
            }
        }
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}
