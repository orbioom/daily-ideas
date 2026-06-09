import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var foods: [FoodItem]
    @Query private var recipes: [Recipe]

    @AppStorage("portion.calorieTarget") private var calorieTarget = 2000.0
    @AppStorage("portion.units") private var units = "metric"
    @AppStorage("portion.haptics") private var haptics = true

    @State private var showResetCatalog = false
    @State private var showClearRecipes = false

    private var customCount: Int { foods.filter { $0.isCustom }.count }

    var body: some View {
        Form {
            Section("Nutrition targets") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Daily calorie target")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(calorieTarget)) kcal")
                            .font(Brand.mono(14, weight: .semibold))
                            .foregroundStyle(Brand.text2)
                    }
                    Slider(value: $calorieTarget, in: 1200...4000, step: 50)
                        .accessibilityLabel("Daily calorie target")
                        .accessibilityValue("\(Int(calorieTarget)) calories")
                }
            } footer: {
                Text("Used to compute % Daily Value on every recipe label.")
            }

            Section("Units") {
                Picker("Default unit", selection: $units) {
                    Text("Metric (g)").tag("metric")
                    Text("Imperial (oz)").tag("imperial")
                }
                .pickerStyle(.segmented)
            }

            Section("Feedback") {
                Toggle("Interface haptics", isOn: $haptics)
            }

            Section("Catalog") {
                LabeledContent("Foods", value: "\(foods.count)")
                LabeledContent("Custom foods", value: "\(customCount)")
                LabeledContent("Recipes", value: "\(recipes.count)")
            }

            Section {
                Button(role: .destructive) {
                    showResetCatalog = true
                } label: {
                    Label("Reset food catalog to defaults", systemImage: "arrow.counterclockwise")
                }
                Button(role: .destructive) {
                    showClearRecipes = true
                } label: {
                    Label("Clear all recipes", systemImage: "trash")
                }
            } footer: {
                Text("Resetting the catalog removes your \(customCount) custom food\(customCount == 1 ? "" : "s") and re-seeds the built-ins. Everything stays on this device.")
            }

            Section {
                LabeledContent("Portion", value: "1.0")
            } footer: {
                Text("Conjured, not just coded. All data is stored on-device.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.pageBackground)
        .navigationTitle("Settings")
        .confirmationDialog("Reset food catalog?", isPresented: $showResetCatalog, titleVisibility: .visible) {
            Button("Reset catalog", role: .destructive) { resetCatalog() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deletes all foods (including \(customCount) custom) and re-seeds the defaults. Saved recipes keep their snapshotted nutrition.")
        }
        .confirmationDialog("Clear all recipes?", isPresented: $showClearRecipes, titleVisibility: .visible) {
            Button("Clear \(recipes.count) recipe\(recipes.count == 1 ? "" : "s")", role: .destructive) { clearRecipes() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every recipe. The food catalog is untouched.")
        }
    }

    private func resetCatalog() {
        for food in foods { context.delete(food) }
        try? context.save()
        SeedData.reseedFoods(context)    // re-seeds the built-in foods only
        Haptics.warning()
    }

    private func clearRecipes() {
        for recipe in recipes { context.delete(recipe) }
        try? context.save()
        Haptics.warning()
    }
}
