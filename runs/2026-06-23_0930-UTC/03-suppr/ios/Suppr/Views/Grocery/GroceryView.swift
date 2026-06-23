import SwiftUI
import SwiftData

struct GroceryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GroceryItem.name) private var items: [GroceryItem]
    @Query private var meals: [PlannedMeal]
    @Query private var pantry: [PantryStaple]
    @Query private var settingsList: [AppSettings]

    @State private var showingAdd = false
    @State private var isRegenerating = false
    @State private var showClearChecked = false

    private var settings: AppSettings { settingsList.first ?? AppSettings() }

    /// Set of pantry match keys the cook has on-hand.
    private var onHandKeys: Set<String> {
        Set(pantry.filter { $0.haveOnHand }.map { $0.matchKey })
    }

    /// Items visible after applying staple + pantry-aware filters.
    private var visibleItems: [GroceryItem] {
        items.filter { item in
            if settings.hideStaplesOnList && item.isStaple && !item.isManual { return false }
            if settings.pantryAwareList && !item.isManual {
                let key = item.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if onHandKeys.contains(key) { return false }
            }
            return true
        }
    }

    private var grouped: [(aisle: Aisle, items: [GroceryItem])] {
        GroceryEngine.grouped(visibleItems)
    }

    private var checkedCount: Int { visibleItems.filter { $0.isChecked }.count }
    private var hiddenCount: Int { items.count - visibleItems.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if isRegenerating {
                    ProgressView("Building your list…")
                        .tint(Theme.terracotta)
                } else if visibleItems.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Grocery")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button { regenerate() } label: {
                            Label("Rebuild from plan", systemImage: "arrow.triangle.2.circlepath")
                        }
                        Button(role: .destructive) { showClearChecked = true } label: {
                            Label("Clear checked items", systemImage: "checklist.checked")
                        }
                        .disabled(checkedCount == 0)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("List options")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true; Haptics.tap() } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add item")
                }
            }
            .sheet(isPresented: $showingAdd) { AddGroceryItemSheet() }
            .alert("Clear checked items?", isPresented: $showClearChecked) {
                Button("Clear \(checkedCount)", role: .destructive) {
                    PlanStore(context: context).clearChecked()
                    Haptics.success()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: meals.isEmpty ? "cart" : "checkmark.seal",
            title: meals.isEmpty ? "Your list is empty" : "All set",
            message: meals.isEmpty
                ? "Plan some meals and Suppr will build a shopping list automatically — or add an item by hand."
                : "Everything on your list is either checked off or already in your pantry.",
            actionTitle: "Add an item",
            action: { showingAdd = true }
        )
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 14) {
                summaryHeader
                ForEach(grouped, id: \.aisle) { group in
                    AisleSection(aisle: group.aisle, items: group.items, scale: scale)
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
    }

    private var summaryHeader: some View {
        let total = visibleItems.count
        let progress = total == 0 ? 0 : Double(checkedCount) / Double(total)
        return VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(checkedCount) of \(total) gathered")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.primaryText)
                    if hiddenCount > 0 {
                        Text("\(hiddenCount) hidden (pantry / staples)")
                            .font(.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(Theme.terracotta)
            }
            ProgressView(value: progress)
                .tint(Theme.sage)
        }
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(checkedCount) of \(total) items gathered")
    }

    private func quantity(for item: GroceryItem) -> String? {
        Quantity.line(quantity: item.quantity, unit: item.unit)
    }

    private func scale(_ item: GroceryItem) -> String? { quantity(for: item) }

    private func regenerate() {
        isRegenerating = true
        Haptics.tap()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            let all = (try? context.fetch(FetchDescriptor<PlannedMeal>())) ?? []
            PlanStore(context: context).regenerateGroceryList(from: all)
            isRegenerating = false
            Haptics.success()
        }
    }
}

/// One aisle section in the grocery list.
struct AisleSection: View {
    let aisle: Aisle
    let items: [GroceryItem]
    let scale: (GroceryItem) -> String?

    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: aisle.symbol)
                    .foregroundStyle(Theme.terracotta)
                    .accessibilityHidden(true)
                Text(aisle.rawValue)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Text("\(items.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
            }
            ForEach(items) { item in
                GroceryRow(item: item, detail: scale(item))
                if item.id != items.last?.id {
                    Divider().overlay(Theme.hairline)
                }
            }
        }
        .cardSurface()
    }
}

struct GroceryRow: View {
    @Bindable var item: GroceryItem
    let detail: String?

    @Environment(\.modelContext) private var context

    var body: some View {
        Button {
            PlanStore(context: context).toggle(item)
            Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isChecked ? Theme.sage : Theme.secondaryText)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.subheadline)
                        .strikethrough(item.isChecked, color: Theme.secondaryText)
                        .foregroundStyle(item.isChecked ? Theme.secondaryText : Theme.primaryText)
                    if item.isManual {
                        Text("Added by you")
                            .font(.caption2)
                            .foregroundStyle(Theme.amber)
                    }
                }
                Spacer()
                if let detail {
                    Text(detail)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name)\(detail.map { ", \($0)" } ?? "")")
        .accessibilityValue(item.isChecked ? "Checked" : "Not checked")
        .accessibilityHint("Double tap to toggle")
        .swipeActions {
            Button(role: .destructive) {
                PlanStore(context: context).delete(item)
                Haptics.warning()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
