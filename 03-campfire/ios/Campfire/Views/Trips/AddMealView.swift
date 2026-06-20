import SwiftUI
import SwiftData

struct AddMealView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let trip: CampTrip

    @State private var dayNumber = 1
    @State private var mealType: MealType = .breakfast
    @State private var description = ""
    @State private var prepMethod: MealPrep = .campfire
    @State private var servings = 2
    @State private var ingredients = ""

    private var maxDay: Int { trip.duration }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    Picker("Day", selection: $dayNumber) {
                        ForEach(1...max(1, maxDay), id: \.self) { d in
                            Text("Day \(d)").tag(d)
                        }
                    }
                    .accessibilityLabel("Trip day")
                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .accessibilityLabel("Meal type")
                }

                Section("Meal") {
                    TextField("Description (e.g. Campfire chili)", text: $description)
                        .accessibilityLabel("Meal description")
                    Picker("Prep Method", selection: $prepMethod) {
                        ForEach(MealPrep.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .accessibilityLabel("Preparation method")
                    Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                        .accessibilityLabel("Servings: \(servings)")
                }

                Section("Ingredients") {
                    TextEditor(text: $ingredients)
                        .frame(minHeight: 80)
                        .accessibilityLabel("Ingredient list")
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(description.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = description.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let meal = MealPlan(dayNumber: dayNumber, mealType: mealType, description: trimmed, trip: trip)
        meal.prepMethod = prepMethod
        meal.servings = servings
        meal.ingredients = ingredients
        context.insert(meal)
        try? context.save()
        dismiss()
    }
}
