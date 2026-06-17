import SwiftUI
import SwiftData

/// The persistent, searchable history tape. Each evaluated `=` is saved here.
struct HistoryView: View {
    @Bindable var calculator: CalculatorModel
    @Binding var selectedTab: SigmaTab

    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(\.modelContext) private var context

    @Query(sort: \CalcEntry.timestamp, order: .reverse) private var entries: [CalcEntry]
    @State private var searchText = ""
    @State private var showClearConfirm = false
    @State private var showInserted = false
    @State private var showPaywall = false

    private var filtered: [CalcEntry] {
        guard !searchText.isEmpty else { return entries }
        let needle = searchText.lowercased()
        return entries.filter {
            $0.expression.lowercased().contains(needle) || $0.result.lowercased().contains(needle)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !entries.isEmpty {
                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .accessibilityLabel("Clear all history")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search expressions or results")
            .toast(isPresented: $showInserted, message: "Added to keypad", systemImage: "plus.circle.fill")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .confirmationDialog("Clear all history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Delete \(entries.count) entries", role: .destructive) { clearAll() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This permanently removes every saved calculation.")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if entries.isEmpty {
            EmptyStateView(systemImage: "list.bullet.rectangle.portrait",
                           title: "No calculations yet",
                           message: "Tap = on the calculator and your results will be saved here automatically.",
                           actionTitle: "Open Calculator") {
                selectedTab = .calculator
            }
        } else if filtered.isEmpty {
            EmptyStateView(systemImage: "magnifyingglass",
                           title: "No matches",
                           message: "Nothing in your tape matches \"\(searchText)\".")
        } else {
            List {
                if !pro.isPro {
                    ProUpsellBanner(icon: "infinity",
                                    title: "Free tape keeps your last \(ProStore.freeHistoryCap)",
                                    subtitle: "Unlock Pro for unlimited history.") {
                        showPaywall = true
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                }
                ForEach(filtered) { entry in
                    HistoryRow(entry: entry,
                               onInsertResult: { value in insert(value, expression: false) },
                               onInsertExpression: { expr in insert(expr, expression: true) })
                        .listRowBackground(Theme.surface)
                }
                .onDelete(perform: delete)
            }
            .scrollContentBackground(.hidden)
        }
    }

    // MARK: Actions

    private func insert(_ value: String, expression: Bool) {
        if expression {
            calculator.insertExpression(value)
        } else {
            calculator.insertResult(value)
        }
        calculator.refreshPreview(places: settings.effectivePlaces,
                                  grouping: settings.groupingEnabled,
                                  highPrecision: settings.highPrecision)
        Haptics.selection(enabled: settings.hapticsEnabled)
        showInserted = true
        selectedTab = .calculator
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            guard filtered.indices.contains(index) else { continue }
            context.delete(filtered[index])
        }
        try? context.save()
        Haptics.impact(.rigid, enabled: settings.hapticsEnabled)
    }

    private func clearAll() {
        for entry in entries {
            context.delete(entry)
        }
        try? context.save()
        Haptics.warning(enabled: settings.hapticsEnabled)
    }
}
