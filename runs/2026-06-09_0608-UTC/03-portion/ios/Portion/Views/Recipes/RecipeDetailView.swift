import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var recipe: Recipe

    @AppStorage("portion.calorieTarget") private var calorieTarget = 2000.0

    /// Live scaler — starts at the stored servings, never mutates the recipe.
    @State private var scaledServings: Int = 1
    @State private var showEditor = false

    private var total: Macros { NutritionEngine.total(for: recipe) }
    private var perServing: Macros {
        NutritionEngine.perServing(recipe, servings: scaledServings)
    }
    private var split: (protein: Double, carbs: Double, fat: Double) {
        NutritionEngine.calorieSplit(perServing)
    }
    private var dvRows: [DailyValueRow] {
        NutritionEngine.dailyValuePercents(perServing, calorieTarget: calorieTarget)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if recipe.ingredients.isEmpty {
                    EmptyStateView(
                        icon: "fork.knife",
                        title: "No ingredients",
                        message: "Add ingredients to see this recipe's nutrition label.")
                    Button("Edit recipe") { showEditor = true }
                        .buttonStyle(GlassButtonStyle())
                } else {
                    perServingCard
                    splitCard
                    dailyValueCard
                    ingredientsCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack { RecipeEditorView(recipe: recipe) }
        }
        .onAppear { scaledServings = recipe.safeServings }
    }

    // MARK: - Cards

    private var perServingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Eyebrow(text: "Per serving")
                Spacer()
                if scaledServings != recipe.safeServings {
                    Text("scaled")
                        .font(Brand.mono(11, weight: .medium))
                        .foregroundStyle(Brand.warn)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Format.kcal(perServing.kcal))
                    .font(Brand.mono(44, weight: .bold))
                    .foregroundStyle(Brand.text)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("kcal")
                    .font(Brand.mono(16, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(Format.kcal(perServing.kcal)) calories per serving")

            HStack(spacing: 10) {
                miniMacro("Protein", perServing.protein, MacroColor.protein)
                miniMacro("Carbs", perServing.carbs, MacroColor.carbs)
                miniMacro("Fat", perServing.fat, MacroColor.fat)
                miniMacro("Fiber", perServing.fiber, MacroColor.fiber)
            }

            Divider().overlay(Brand.hairline)

            // Live serving scaler
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Servings")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Text("\(scaledServings)")
                        .font(Brand.mono(16, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
                Stepper(value: $scaledServings, in: 1...100) {
                    Text("Adjust servings")
                        .font(.footnote)
                        .foregroundStyle(Brand.text3)
                }
                .onChange(of: scaledServings) { _, _ in Haptics.selection() }

                if scaledServings != recipe.safeServings {
                    Button {
                        Haptics.success()
                        recipe.servings = scaledServings
                        try? context.save()
                    } label: {
                        Label("Save \(scaledServings) as the recipe's servings",
                              systemImage: "square.and.arrow.down")
                            .font(.footnote)
                    }
                    .tint(Brand.live)
                }
            }

            Text("Whole recipe: \(Format.kcal(total.kcal)) kcal · \(Format.grams(total.protein)) protein · \(Format.grams(total.carbs)) carbs · \(Format.grams(total.fat)) fat")
                .font(.footnote)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var splitCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(text: "Calorie split")
            HStack(spacing: 18) {
                CalorieSplitDonut(split: split, kcal: perServing.kcal)
                    .frame(width: 150)
                VStack(spacing: 12) {
                    MacroLegendRow(color: MacroColor.protein, name: "Protein",
                                   percent: split.protein, grams: perServing.protein)
                    MacroLegendRow(color: MacroColor.carbs, name: "Carbs",
                                   percent: split.carbs, grams: perServing.carbs)
                    MacroLegendRow(color: MacroColor.fat, name: "Fat",
                                   percent: split.fat, grams: perServing.fat)
                }
            }
        }
        .glassCard()
    }

    private var dailyValueCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                SectionTitle(text: "% Daily Value")
                Spacer()
                Text("per serving")
                    .font(Brand.mono(11, weight: .medium))
                    .foregroundStyle(Brand.text3)
            }
            ForEach(dvRows) { row in
                MacroBar(label: row.name,
                         value: "\(NutritionEngine.gramsString(row.amount)) \(row.unit) · \(Format.percent(row.percent))",
                         fraction: row.percent,
                         tint: tint(for: row.name))
            }
            Text("Based on a \(Int(calorieTarget)) kcal daily target. Change it in Settings.")
                .font(.footnote)
                .foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Ingredients")
            ForEach(recipe.orderedIngredients) { ing in
                let m = NutritionEngine.macros(for: ing)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ing.foodName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                        Text("\(ing.amountLabel) · \(Format.grams(ing.grams))")
                            .font(Brand.mono(12))
                            .foregroundStyle(Brand.text3)
                    }
                    Spacer()
                    Text("\(Format.kcal(m.kcal)) kcal")
                        .font(Brand.mono(13, weight: .semibold))
                        .foregroundStyle(Brand.text2)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(ing.foodName), \(ing.amountLabel), \(Format.kcal(m.kcal)) calories")
                if ing.id != recipe.orderedIngredients.last?.id {
                    Divider().overlay(Brand.hairline)
                }
            }
        }
        .glassCard()
    }

    // MARK: - Helpers

    private func miniMacro(_ label: String, _ grams: Double, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(Format.gramsValue(grams))
                .font(Brand.mono(17, weight: .semibold))
                .foregroundStyle(Brand.text)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label.uppercased())
                .font(Brand.mono(9, weight: .medium))
                .tracking(0.8)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(Format.grams(grams))")
    }

    private func tint(for name: String) -> Color {
        switch name {
        case "Protein": return MacroColor.protein
        case "Carbohydrate": return MacroColor.carbs
        case "Fat": return MacroColor.fat
        case "Fiber": return MacroColor.fiber
        default: return Brand.live
        }
    }
}
