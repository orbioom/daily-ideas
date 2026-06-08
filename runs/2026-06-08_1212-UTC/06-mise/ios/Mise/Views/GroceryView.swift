import SwiftUI
import SwiftData

struct GroceryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \GroceryItem.order) private var items: [GroceryItem]
    @Query private var plans: [MealPlan]

    @State private var newItemName = ""
    @State private var showGenerateSheet = false
    @State private var generatedNotice = false

    private let engine = MealEngine()
    private let calendar = Calendar.current

    private var grouped: [(aisle: Aisle, items: [GroceryItem])] {
        Aisle.allCases.compactMap { aisle in
            let inAisle = items.filter { $0.aisle == aisle }
                .sorted { ($0.checked ? 1 : 0, $0.name.lowercased()) < ($1.checked ? 1 : 0, $1.name.lowercased()) }
            return inAisle.isEmpty ? nil : (aisle, inAisle)
        }
    }

    private var checkedCount: Int { items.filter { $0.checked }.count }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    if items.isEmpty {
                        EmptyStateView(
                            icon: "cart",
                            title: "Your list is empty",
                            message: "Generate a shopping list from your meal plan, or add items by hand below."
                        )
                    } else {
                        progressHeader
                        List {
                            ForEach(grouped, id: \.aisle) { group in
                                Section {
                                    ForEach(group.items) { item in itemRow(item) }
                                } header: {
                                    Label(group.aisle.label, systemImage: group.aisle.symbol)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                    addBar
                }
            }
            .navigationTitle("Grocery")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showGenerateSheet = true } label: {
                            Label("Generate from plan", systemImage: "wand.and.stars")
                        }
                        if checkedCount > 0 {
                            Button(role: .destructive) { clearChecked() } label: {
                                Label("Clear checked (\(checkedCount))", systemImage: "trash")
                            }
                        }
                        if !items.isEmpty {
                            Button(role: .destructive) { clearAll() } label: {
                                Label("Clear all", systemImage: "xmark.bin")
                            }
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                        .accessibilityLabel("List options")
                }
            }
            .sheet(isPresented: $showGenerateSheet) {
                GenerateSheet { range in generate(range: range) }
            }
            .alert("List updated", isPresented: $generatedNotice) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Ingredients from your plan were added and combined by item.")
            }
        }
    }

    private var progressHeader: some View {
        let total = items.count
        let fraction = total == 0 ? 0 : Double(checkedCount) / Double(total)
        return VStack(spacing: 6) {
            HStack {
                Text("\(checkedCount) of \(total) in the cart")
                    .font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
                Text(Format.percent(fraction))
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(checkedCount == total ? Brand.live : Color.accentColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.hairline).frame(height: 6)
                    Capsule().fill(checkedCount == total ? Brand.live : Color.accentColor)
                        .frame(width: max(6, geo.size.width * fraction), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal).padding(.vertical, 10)
    }

    private func itemRow(_ item: GroceryItem) -> some View {
        Button {
            item.checked.toggle(); Haptics.selection()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                    .font(.title3).foregroundStyle(item.checked ? Brand.live : Brand.text3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.body).foregroundStyle(item.checked ? Brand.text3 : Brand.text)
                        .strikethrough(item.checked, color: Brand.text3)
                    if item.quantity > 0 || item.unit != .none {
                        Text(Quantity.withUnit(item.quantity, unit: item.unit))
                            .font(Brand.mono(11)).foregroundStyle(Brand.text3)
                    }
                }
                Spacer()
                if item.manual {
                    Image(systemName: "hand.draw").font(.caption2).foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .swipeActions {
            Button(role: .destructive) { context.delete(item); Haptics.warning() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .accessibilityLabel("\(item.name), \(item.checked ? "in cart" : "needed")")
    }

    private var addBar: some View {
        HStack(spacing: 8) {
            TextField("Add item…", text: $newItemName)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addManual)
            Button { addManual() } label: {
                Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Color.accentColor)
            }
            .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Add item")
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Actions

    private func addManual() {
        let name = newItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let order = (items.map { $0.order }.max() ?? 0) + 1
        context.insert(GroceryItem(name: name, manual: true, order: order))
        newItemName = ""
        Haptics.tap()
    }

    private func generate(range: GenerateSheet.Range) {
        // Remove existing auto-generated (non-manual) items; keep manual & checked-manual.
        for item in items where !item.manual { context.delete(item) }

        let today = calendar.startOfDay(for: .now)
        let scoped: [MealPlan]
        switch range {
        case .next7:
            let end = calendar.date(byAdding: .day, value: 7, to: today) ?? today
            scoped = plans.filter { $0.date >= today && $0.date < end }
        case .upcoming:
            scoped = plans.filter { $0.date >= today }
        case .all:
            scoped = plans
        }

        let aggregated = engine.groceryList(from: scoped)
        var order = (items.map { $0.order }.max() ?? 0) + 1
        for agg in aggregated {
            // If a manual item with the same name exists, skip to avoid duplicates.
            if items.contains(where: { $0.manual && $0.name.lowercased() == agg.name.lowercased() }) { continue }
            context.insert(GroceryItem(name: agg.name, quantity: agg.quantity, unit: agg.unit,
                                       aisle: agg.aisle, manual: false, order: order))
            order += 1
        }
        try? context.save()
        Haptics.success()
        generatedNotice = true
    }

    private func clearChecked() {
        for item in items where item.checked { context.delete(item) }
        try? context.save(); Haptics.warning()
    }

    private func clearAll() {
        for item in items { context.delete(item) }
        try? context.save(); Haptics.warning()
    }
}

struct GenerateSheet: View {
    enum Range: String, CaseIterable, Identifiable {
        case next7 = "Next 7 days", upcoming = "All upcoming", all = "Entire plan"
        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .next7: return "calendar"
            case .upcoming: return "calendar.badge.clock"
            case .all: return "infinity"
            }
        }
    }
    let onGenerate: (Range) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 14) {
                    Text("Build your list from the meals you've planned. Existing hand-added items stay.")
                        .font(.subheadline).foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center).padding(.horizontal)
                        .padding(.top, 8)
                    ForEach(Range.allCases) { range in
                        Button {
                            onGenerate(range); dismiss()
                        } label: {
                            HStack {
                                Image(systemName: range.symbol).foregroundStyle(Color.accentColor)
                                Text(range.rawValue).foregroundStyle(Brand.text)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(Brand.text3)
                            }
                            .glassCard(padding: 16)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                    Spacer()
                }
            }
            .navigationTitle("Generate list")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } } }
            .presentationDetents([.medium])
        }
    }
}
