import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var context
    @Query private var plans: [MealPlan]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]

    @AppStorage("weekStartsMonday") private var weekStartsMonday = false
    @AppStorage("defaultServings") private var defaultServings = 2
    @State private var weekOffset = 0

    private let engine = MealEngine()
    private var calendar: Calendar {
        var c = Calendar.current
        c.firstWeekday = weekStartsMonday ? 2 : 1
        return c
    }

    private var weekStart: Date {
        let base = calendar.date(byAdding: .day, value: weekOffset * 7, to: .now) ?? .now
        let interval = calendar.dateInterval(of: .weekOfYear, for: base)
        return calendar.startOfDay(for: interval?.start ?? base)
    }
    private var days: [Date] { engine.days(from: weekStart, count: 7) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 14) {
                        weekHeader
                        ForEach(days, id: \.self) { day in
                            dayCard(day)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Plan")
            .sheet(item: $assignCtx) { ctx in
                RecipePickerSheet(recipes: recipes, defaultServings: defaultServings) { recipe, servings in
                    assign(recipe, servings: servings, to: ctx.date, meal: ctx.meal)
                }
            }
        }
    }

    // Wrap the date + meal slot into Identifiable for sheet(item:).
    private struct AssignContext: Identifiable { let id = UUID(); let date: Date; let meal: MealType }
    @State private var assignCtx: AssignContext?

    private var weekHeader: some View {
        HStack {
            Button { withAnimation(Brand.ease(0.25)) { weekOffset -= 1 } } label: { Image(systemName: "chevron.left") }
                .accessibilityLabel("Previous week")
            Spacer()
            VStack(spacing: 1) {
                Text(weekLabel).font(.headline).foregroundStyle(Brand.text)
                Text("\(engine.plannedRecipeCount(weekPlans)) meals planned")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            Button { withAnimation(Brand.ease(0.25)) { weekOffset += 1 } } label: { Image(systemName: "chevron.right") }
                .accessibilityLabel("Next week")
        }
        .padding(.horizontal, 4)
    }

    private var weekPlans: [MealPlan] {
        plans.filter { p in days.contains { calendar.isDate($0, inSameDayAs: p.date) } }
    }

    private var weekLabel: String {
        guard let last = days.last else { return "" }
        return "\(Format.shortDate.string(from: weekStart)) – \(Format.shortDate.string(from: last))"
    }

    private func dayCard(_ day: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Format.dayFull.string(from: day))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(calendar.isDateInToday(day) ? Color.accentColor : Brand.text)
                if calendar.isDateInToday(day) {
                    Text("Today").font(.caption2).foregroundStyle(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.accentColor, in: Capsule())
                }
                Spacer()
            }
            ForEach(MealType.allCases) { meal in
                mealRow(day, meal)
            }
        }
        .glassCard(padding: 14)
    }

    private func mealRow(_ day: Date, _ meal: MealType) -> some View {
        let plan = engine.plans(plans, on: day).first { $0.mealType == meal }
        return HStack(spacing: 10) {
            Image(systemName: meal.symbol).font(.caption).foregroundStyle(Brand.text3).frame(width: 22)
            Text(meal.label).font(.caption).foregroundStyle(Brand.text3).frame(width: 64, alignment: .leading)
            if let plan, let recipe = plan.recipe {
                Button {
                    assignCtx = AssignContext(date: day, meal: meal)
                } label: {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: recipe.colorHex)).frame(width: 8, height: 8)
                        Text(recipe.name).font(.subheadline).foregroundStyle(Brand.text).lineLimit(1)
                        Text("· \(plan.servings)").font(.caption2).foregroundStyle(Brand.text3)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                Button {
                    context.delete(plan); Haptics.warning()
                } label: { Image(systemName: "xmark.circle.fill").font(.caption).foregroundStyle(Brand.text3) }
                    .accessibilityLabel("Remove \(meal.label)")
            } else {
                Button {
                    if recipes.isEmpty { return }
                    assignCtx = AssignContext(date: day, meal: meal)
                } label: {
                    HStack {
                        Text(recipes.isEmpty ? "Add a recipe first" : "Add")
                            .font(.subheadline).foregroundStyle(recipes.isEmpty ? Brand.text3 : Color.accentColor)
                        Spacer()
                        if !recipes.isEmpty { Image(systemName: "plus.circle").foregroundStyle(Color.accentColor) }
                    }
                }
                .buttonStyle(.plain)
                .disabled(recipes.isEmpty)
            }
        }
    }

    private func assign(_ recipe: Recipe, servings: Int, to day: Date, meal: MealType) {
        let dayStart = calendar.startOfDay(for: day)
        if let existing = engine.plans(plans, on: day).first(where: { $0.mealType == meal }) {
            existing.recipe = recipe
            existing.servings = servings
        } else {
            context.insert(MealPlan(date: dayStart, mealType: meal, servings: servings, recipe: recipe))
        }
        Haptics.success()
    }
}

struct RecipePickerSheet: View {
    let recipes: [Recipe]
    var defaultServings: Int = 2
    let onPick: (Recipe, Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var servings: Int
    @State private var search = ""

    init(recipes: [Recipe], defaultServings: Int = 2, onPick: @escaping (Recipe, Int) -> Void) {
        self.recipes = recipes
        self.defaultServings = defaultServings
        self.onPick = onPick
        _servings = State(initialValue: defaultServings)
    }

    private var filtered: [Recipe] {
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty ? recipes : recipes.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                VStack(spacing: 0) {
                    Stepper("Servings: \(servings)", value: $servings, in: 1...50)
                        .padding()
                    List {
                        ForEach(filtered) { r in
                            Button {
                                onPick(r, servings); dismiss()
                            } label: {
                                HStack(spacing: 10) {
                                    Circle().fill(Color(hex: r.colorHex)).frame(width: 10, height: 10)
                                    Text(r.name).foregroundStyle(Brand.text)
                                    Spacer()
                                    Text(r.course.label).font(.caption).foregroundStyle(Brand.text3)
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Choose recipe")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancel") { dismiss() } } }
        }
    }
}
