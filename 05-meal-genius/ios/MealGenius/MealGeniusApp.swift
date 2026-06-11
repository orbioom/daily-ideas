import SwiftUI
import SwiftData

@Model final class Recipe {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var servings: Int = 1
    @Relationship(deleteRule: .cascade) var ingredients: [Ingredient] = []
    @Relationship(deleteRule: .cascade) var steps: [RecipeStep] = []
    var prep: Int = 15
    var cook: Int = 30

    var totalCost: Double { ingredients.reduce(0) { $0 + $1.cost } }
    var costPerServing: Double { totalCost / Double(max(servings, 1)) }
}

@Model final class Ingredient {
    @Attribute(.unique) var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var cost: Double = 0

    var display: String { "\(quantity) \(unit) \(name)" }
}

@Model final class RecipeStep {
    @Attribute(.unique) var id: UUID = UUID()
    var order: Int
    var instruction: String
}

@Model final class MealPlan {
    @Attribute(.unique) var id: UUID = UUID()
    var week: String
    @Relationship(deleteRule: .cascade) var meals: [PlannedMeal] = []
    var createdAt: Date = Date()
}

@Model final class PlannedMeal {
    @Attribute(.unique) var id: UUID = UUID()
    var recipeName: String
    var servings: Int
    var day: String
    var mealType: String // breakfast, lunch, dinner
}

@main
struct MealGeniusApp: App {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false

    var modelContainer: ModelContainer = {
        let schema = Schema([Recipe.self, Ingredient.self, RecipeStep.self, MealPlan.self, PlannedMeal.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                MainView()
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            }
        }
        .modelContainer(modelContainer)
    }
}

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("🍳").font(.system(size: 80))
            VStack {
                Text("Meal Genius")
                    .font(.title).fontWeight(.bold)
                Text("AI meal planning + smart grocery lists")
                    .font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
            }
            Spacer()
            Button(action: { hasSeenOnboarding = true }) {
                Text("Get Started").frame(maxWidth: .infinity).padding().background(Color.accentColor).foregroundColor(.white).cornerRadius(8)
            }
        }
        .padding()
    }
}

struct MainView: View {
    @Query var recipes: [Recipe]
    @Query var plans: [MealPlan]
    @State var showAddRecipe = false

    var body: some View {
        TabView {
            NavigationStack {
                VStack {
                    if recipes.isEmpty {
                        VStack {
                            Text("No recipes yet").font(.headline)
                            Text("Add recipes to start meal planning").font(.body).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(recipes) { recipe in
                                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.name).font(.headline)
                                        Text("\(recipe.ingredients.count) ingredients • $\(String(format: "%.2f", recipe.costPerServing))/serving").font(.caption).foregroundColor(.secondary)
                                    }
                                }
                            }
                            .onDelete { indices in
                                indices.forEach { _ in }
                            }
                        }
                    }
                }
                .navigationTitle("Recipes")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showAddRecipe = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .tabItem { Label("Recipes", systemImage: "book.fill") }

            NavigationStack {
                if plans.isEmpty {
                    VStack {
                        Text("No meal plans yet").font(.headline)
                    }
                } else {
                    List {
                        ForEach(plans) { plan in
                            NavigationLink(destination: MealPlanDetailView(plan: plan)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(plan.week).font(.headline)
                                    Text("\(plan.meals.count) meals planned").font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Meal Plans")
            }
            .tabItem { Label("Plans", systemImage: "calendar") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .sheet(isPresented: $showAddRecipe) {
            AddRecipeView()
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe

    var body: some View {
        VStack {
            List {
                Section("Ingredients") {
                    ForEach(recipe.ingredients) { ing in
                        Text("\(ing.quantity) \(ing.unit) \(ing.name)")
                    }
                }
                Section("Steps") {
                    ForEach(recipe.steps.sorted { $0.order < $1.order }) { step in
                        Text(step.instruction)
                    }
                }
                Section("Cost") {
                    LabeledContent("Total", value: "$\(String(format: "%.2f", recipe.totalCost))")
                    LabeledContent("Per Serving", value: "$\(String(format: "%.2f", recipe.costPerServing))")
                }
            }
        }
        .navigationTitle(recipe.name)
    }
}

struct MealPlanDetailView: View {
    let plan: MealPlan

    var body: some View {
        VStack {
            List {
                ForEach(plan.meals) { meal in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.day).font(.headline)
                        Text(meal.mealType.capitalized).font(.caption).foregroundColor(.secondary)
                        Text(meal.recipeName)
                    }
                }
            }
        }
        .navigationTitle(plan.week)
    }
}

struct AddRecipeView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @State var name = ""
    @State var ingredients: [String] = [""]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Recipe name", text: $name)
                Section("Ingredients") {
                    ForEach($ingredients, id: \.self) { $ing in
                        TextField("Ingredient", text: $ing)
                    }
                    Button(action: { ingredients.append("") }) {
                        Label("Add Ingredient", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("New Recipe")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        let recipe = Recipe(name: name)
                        for (idx, ing) in ingredients.filter({ !$0.isEmpty }).enumerated() {
                            let ingredient = Ingredient(name: ing, quantity: 1, unit: "serving")
                            recipe.ingredients.append(ingredient)
                        }
                        modelContext.insert(recipe)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
