import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var recipes: [Recipe]
    @Query private var plans: [MealPlan]
    @Query private var groceries: [GroceryItem]

    @AppStorage("appearance") private var appearanceRaw = AppearanceMode.system.rawValue
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("defaultServings") private var defaultServings = 2
    @AppStorage("weekStartsMonday") private var weekStartsMonday = false

    @State private var showErase = false

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Form {
                    Section("Appearance") {
                        Picker("Theme", selection: $appearanceRaw) {
                            ForEach(AppearanceMode.allCases) { Text($0.label).tag($0.rawValue) }
                        }
                    }
                    Section {
                        Stepper("Default servings: \(defaultServings)", value: $defaultServings, in: 1...20)
                        Toggle("Week starts on Monday", isOn: $weekStartsMonday)
                    } header: {
                        Text("Cooking")
                    } footer: {
                        Text("Default servings is the starting amount when you add a recipe to your plan.")
                    }
                    Section("Feedback") {
                        Toggle("Haptics", isOn: $hapticsEnabled)
                    }
                    Section {
                        LabeledContent("Recipes", value: "\(recipes.count)")
                        LabeledContent("Planned meals", value: "\(plans.count)")
                        LabeledContent("Grocery items", value: "\(groceries.count)")
                        Button(role: .destructive) { showErase = true } label: { Text("Erase everything") }
                            .disabled(recipes.isEmpty && plans.isEmpty && groceries.isEmpty)
                    } header: {
                        Text("Data")
                    } footer: {
                        Text("All stored on this device — buy once, no per-device fees, no cloud, no ads.")
                    }
                    Section {
                        LabeledContent("Version", value: "1.0")
                    } footer: {
                        Text("Mise — cook from what you planned. Conjured, not just coded.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .confirmationDialog("Erase all recipes, plans, and grocery items?",
                                isPresented: $showErase, titleVisibility: .visible) {
                Button("Erase Everything", role: .destructive) {
                    for g in groceries { context.delete(g) }
                    for p in plans { context.delete(p) }
                    for r in recipes { context.delete(r) }
                    try? context.save(); Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
