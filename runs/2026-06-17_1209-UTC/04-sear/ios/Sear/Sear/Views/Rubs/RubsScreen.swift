import SwiftUI
import SwiftData

/// Rub recipe collection: built-in classics to copy + the user's own rubs (CRUD).
struct RubsScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @AppStorage("isPro") private var isPro = false
    @Query(sort: \Rub.createdAt, order: .reverse) private var rubs: [Rub]

    @State private var editingRub: Rub?
    @State private var showNew = false
    @State private var paywallReason: PaywallReason?

    private var customCount: Int { rubs.filter { $0.isBuiltInCopy }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Rubs")
            .navigationDestination(for: Rub.self) { RubDetailView(rub: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { newRub() } label: {
                        Label("New Rub", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNew) {
                RubEditorView(rub: nil)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    @ViewBuilder
    private var content: some View {
        if rubs.isEmpty {
            EmptyStateView(symbol: "fork.knife",
                           title: "No rubs yet",
                           message: "Add your own blend, or reload the built-in classics from Settings.",
                           actionTitle: "New Rub") { newRub() }
        } else {
            List {
                Section {
                    ForEach(rubs) { rub in
                        NavigationLink(value: rub) {
                            RubRow(rub: rub)
                        }
                        .listRowBackground(Theme.surface)
                    }
                    .onDelete(perform: delete)
                } footer: {
                    if !isPro {
                        Text("Free tier keeps \(Pro.freeCustomRubLimit) custom rubs. Built-in classics are always free.")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private func newRub() {
        if !isPro && customCount >= Pro.freeCustomRubLimit {
            paywallReason = .moreRubs
        } else {
            showNew = true
        }
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets {
            if let rub = rubs[safe: index] {
                context.delete(rub)
            }
        }
        try? context.save()
        Haptics.tap(settings.hapticsEnabled)
    }
}

/// Row for a rub in the list.
private struct RubRow: View {
    let rub: Rub
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .foregroundStyle(Theme.accent)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(rub.name)
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                Text("\(rub.ingredients.count) ingredients")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if rub.isBuiltInCopy {
                Pill(text: "Custom", tint: Theme.ember)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
