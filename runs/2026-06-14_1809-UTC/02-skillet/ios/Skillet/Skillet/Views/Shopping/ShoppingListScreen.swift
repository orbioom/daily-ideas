import SwiftUI
import SwiftData

/// Aggregated missing ingredients from your queued (favorited) recipes,
/// unlock-ranked. Check items off, then mark them in-stock in the pantry.
struct ShoppingListScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var shopping: ShoppingState
    @AppStorage("isPro") private var isPro = false
    @Query private var recipes: [Recipe]
    @Query private var pantry: [PantryItem]

    @State private var showExport = false
    @State private var paywallReason: PaywallReason?

    private var queued: [Recipe] { recipes.filter { $0.isFavorite } }
    private var have: Set<String> { PantryStore.haveSet(from: pantry) }

    /// Aggregated missing required ingredients across queued recipes.
    private struct Need: Identifiable {
        let normalized: String
        let display: String
        let recipeNames: [String]
        let unlockCount: Int
        var id: String { normalized }
    }

    private var needs: [Need] {
        let unlocks = MatchEngine.shoppingUnlocks(queued, have: have, assumeStaples: settings.assumeStaples)
        let unlockByName = Dictionary(uniqueKeysWithValues: unlocks.map { ($0.normalized, $0.count) })

        var byKey: [String: (display: String, recipes: [String])] = [:]
        for recipe in queued {
            let res = MatchEngine.matchResult(recipe, have: have, assumeStaples: settings.assumeStaples)
            for ing in res.missing {
                let key = ing.normalizedName
                guard !key.isEmpty else { continue }
                if var entry = byKey[key] {
                    if !entry.recipes.contains(recipe.name) { entry.recipes.append(recipe.name) }
                    byKey[key] = entry
                } else {
                    byKey[key] = (display: ing.name, recipes: [recipe.name])
                }
            }
        }

        return byKey
            .map { Need(normalized: $0.key,
                        display: $0.value.display,
                        recipeNames: $0.value.recipes,
                        unlockCount: unlockByName[$0.key] ?? 0) }
            .sorted { lhs, rhs in
                if lhs.unlockCount != rhs.unlockCount { return lhs.unlockCount > rhs.unlockCount }
                if lhs.recipeNames.count != rhs.recipeNames.count { return lhs.recipeNames.count > rhs.recipeNames.count }
                return lhs.display.localizedCaseInsensitiveCompare(rhs.display) == .orderedAscending
            }
    }

    private var toBuy: [Need] { needs.filter { !shopping.isChecked($0.normalized) } }
    private var got: [Need] { needs.filter { shopping.isChecked($0.normalized) } }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Shopping")
            .toolbar { toolbar }
            .sheet(isPresented: $showExport) {
                ShoppingExportView(text: ShoppingExportBuilder.build(needs: needs.map { ($0.display, $0.recipeNames.count) }))
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
        .onAppear {
            shopping.prune(keeping: Set(needs.map { $0.normalized }))
        }
    }

    @ViewBuilder
    private var content: some View {
        if queued.isEmpty {
            EmptyStateView(symbol: "cart",
                           title: "No recipes queued",
                           message: "Favorite a recipe (or tap \"Add missing to shopping list\" on a recipe) and the ingredients you're missing show up here, ranked by how many meals they unlock.")
        } else if needs.isEmpty {
            EmptyStateView(symbol: "checkmark.seal.fill",
                           title: "You're fully stocked",
                           message: "Every queued recipe is ready to cook. Favorite more recipes to build a new list.")
        } else {
            list
        }
    }

    private var list: some View {
        List {
            if let top = toBuy.first, top.unlockCount > 0 {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("Buy **\(top.display)** to unlock \(top.unlockCount) more meal\(top.unlockCount == 1 ? "" : "s").")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.ink)
                    }
                    .listRowBackground(Theme.accentSoft)
                }
            }

            if !toBuy.isEmpty {
                Section("To buy") {
                    ForEach(toBuy) { need in row(need) }
                }
            }

            if !got.isEmpty {
                Section("Got it") {
                    ForEach(got) { need in row(need) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func row(_ need: Need) -> some View {
        let checked = shopping.isChecked(need.normalized)
        return HStack(spacing: 12) {
            Button {
                shopping.toggle(need.normalized)
                Haptics.tap(settings.hapticsEnabled)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(checked ? Theme.good : Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(need.display)
                            .font(Theme.rounded(16, .medium))
                            .foregroundStyle(checked ? Theme.inkSoft : Theme.ink)
                            .strikethrough(checked, color: Theme.inkFaint)
                        Text("For \(need.recipeNames.prefix(2).joined(separator: ", "))\(need.recipeNames.count > 2 ? " +\(need.recipeNames.count - 2)" : "")")
                            .font(Theme.rounded(11))
                            .foregroundStyle(Theme.inkFaint)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(checked ? "got it" : "to buy")
            .accessibilityHint("Double tap to toggle")

            if need.unlockCount > 0 && !checked {
                Text("+\(need.unlockCount)")
                    .font(Theme.rounded(12, .bold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Theme.accent.opacity(0.14)))
                    .accessibilityLabel("Unlocks \(need.unlockCount) recipes")
            }
            if checked {
                Button {
                    markInStock(need)
                } label: {
                    Text("Stock")
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(Theme.good)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add \(need.display) to pantry as in stock")
            }
        }
        .listRowBackground(Theme.surface)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    if isPro { showExport = true } else { paywallReason = .export }
                } label: {
                    Label(isPro ? "Export list" : "Export list (Pro)", systemImage: "square.and.arrow.up")
                }
                if !got.isEmpty {
                    Button {
                        shopping.clearChecked()
                        Haptics.tap(settings.hapticsEnabled)
                    } label: {
                        Label("Clear \"Got it\"", systemImage: "arrow.uturn.backward")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .accessibilityLabel("List options")
            .disabled(needs.isEmpty)
        }
    }

    /// Add the bought ingredient to the pantry as in-stock (or restock existing).
    private func markInStock(_ need: Need) {
        if let match = pantry.first(where: { $0.normalizedName == need.normalized }) {
            match.inStock = true
        } else {
            context.insert(PantryItem(name: need.display,
                                      aisle: Aisle.guess(from: need.display),
                                      inStock: true))
        }
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }
}
