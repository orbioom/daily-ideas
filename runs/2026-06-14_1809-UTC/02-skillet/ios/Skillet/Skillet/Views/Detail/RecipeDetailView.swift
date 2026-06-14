import SwiftUI
import SwiftData

/// Pushed recipe detail: serif title, metadata, have/missing ingredient list,
/// live servings scaler, numbered steps, favorite, add-missing-to-shopping.
struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var shopping: ShoppingState
    @Query private var pantry: [PantryItem]

    @State private var scaledServings: Int = 0
    @State private var addedToList = false
    @State private var showEditor = false

    private var have: Set<String> { PantryStore.haveSet(from: pantry) }
    private var result: MatchResult {
        MatchEngine.matchResult(recipe, have: have, assumeStaples: settings.assumeStaples)
    }

    private var baseServings: Int { max(1, recipe.servings) }
    private var factor: Double {
        guard baseServings > 0 else { return 1 }
        let effective = scaledServings > 0 ? scaledServings : baseServings
        return Double(effective) / Double(baseServings)
    }

    private var visibleIngredients: [RecipeIngredient] {
        settings.hideOptional ? recipe.ingredients.filter { !$0.optional } : recipe.ingredients
    }

    private func isHave(_ ing: RecipeIngredient) -> Bool {
        MatchEngine.isSatisfied(ing, have: have, assumeStaples: settings.assumeStaples)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                statusBanner
                servingsScaler
                ingredientsSection
                stepsSection
                if !recipe.notes.isEmpty { notesSection }
                measurementFootnote
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    recipe.isFavorite.toggle()
                    Haptics.tap(settings.hapticsEnabled)
                    try? context.save()
                } label: {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                }
                .accessibilityLabel(recipe.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEditor = true } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Edit recipe")
            }
        }
        .sheet(isPresented: $showEditor) {
            RecipeEditorView(existing: recipe)
        }
        .onAppear {
            if scaledServings == 0 { scaledServings = baseServings }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(recipe.name)
                .font(Theme.serif(30, .bold))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Pill(text: recipe.cuisine.rawValue, systemImage: recipe.cuisine.symbol, tint: recipe.cuisine.hue)
                Pill(text: recipe.timeLabel, systemImage: "clock", tint: Theme.inkSoft)
                Pill(text: recipe.difficulty.rawValue, systemImage: recipe.difficulty.symbol, tint: recipe.difficulty.color)
            }
        }
    }

    private var statusBanner: some View {
        let tint: Color = result.isMakeable ? Theme.good : (result.oneAway ? Theme.warn : Theme.accent)
        let text: String = result.isMakeable
            ? "You can make this now"
            : (result.oneAway ? "Just one ingredient away" : "\(result.missing.count) ingredients to go")
        return HStack(spacing: 10) {
            Image(systemName: result.isMakeable ? "checkmark.circle.fill" : "cart.fill")
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            Text(text)
                .font(Theme.rounded(15, .semibold))
                .foregroundStyle(tint)
            Spacer()
            Text("\(result.matchPercentInt)%")
                .font(Theme.rounded(15, .bold))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint.opacity(0.12)))
    }

    private var servingsScaler: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Servings", systemImage: "person.2")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Stepper(value: Binding(
                    get: { max(1, scaledServings) },
                    set: { scaledServings = settings.clampedServings($0) }
                ), in: 1...24) {
                    Text("\(max(1, scaledServings))")
                        .font(Theme.rounded(16, .bold))
                        .foregroundStyle(Theme.accent)
                        .monospacedDigit()
                }
                .labelsHidden()
            }
            if scaledServings != baseServings {
                Text("Scaled from \(baseServings) — amounts adjust below.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.surface))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 1))
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Ingredients")
            ForEach(visibleIngredients) { ing in
                ingredientRow(ing)
            }
            if !result.missing.isEmpty {
                Button {
                    addMissingToShopping()
                } label: {
                    Label(addedToList ? "Added to shopping list" : "Add missing to shopping list",
                          systemImage: addedToList ? "checkmark.circle.fill" : "cart.badge.plus")
                        .font(Theme.rounded(15, .semibold))
                        .foregroundStyle(addedToList ? Theme.good : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(addedToList ? Theme.good.opacity(0.15) : Theme.accent))
                }
                .padding(.top, 4)
            }
        }
    }

    private func ingredientRow(_ ing: RecipeIngredient) -> some View {
        let have = isHave(ing)
        let scaledAmount = ing.amount.isEmpty ? "" : AmountScaler.scale(ing.amount, factor: factor)
        return HStack(spacing: 10) {
            Image(systemName: have ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(have ? Theme.good : Theme.bad)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(ing.name)
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(have ? Theme.ink : Theme.bad)
                    if ing.optional {
                        Text("optional")
                            .font(Theme.rounded(10, .semibold))
                            .foregroundStyle(Theme.inkFaint)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Capsule().fill(Theme.inkFaint.opacity(0.15)))
                    }
                }
                if !scaledAmount.isEmpty {
                    Text(scaledAmount)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ing.name)\(ing.optional ? ", optional" : "")")
        .accessibilityValue(have ? "have it" : "missing")
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Method")
            let steps = recipe.steps
            if steps.isEmpty {
                Text("No steps recorded for this recipe.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(Theme.rounded(14, .bold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Theme.accent))
                            .accessibilityHidden(true)
                        Text(step)
                            .font(Theme.rounded(15))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Notes")
            Text(recipe.notes)
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var measurementFootnote: some View {
        Text("Measurements shown in \(settings.measurementNote).")
            .font(Theme.rounded(11))
            .foregroundStyle(Theme.inkFaint)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(Theme.serif(20, .bold))
            .foregroundStyle(Theme.ink)
    }

    private func addMissingToShopping() {
        // Adding = ensure the recipe is queued (favorited) so the shopping list
        // aggregates it; checked-off items are cleared for these names.
        recipe.isFavorite = true
        shopping.clearChecked(for: result.missing.map { $0.normalizedName })
        try? context.save()
        addedToList = true
        Haptics.success(settings.hapticsEnabled)
    }
}
