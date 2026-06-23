import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PlannedMeal.addedAt) private var meals: [PlannedMeal]
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Query private var settingsList: [AppSettings]

    @State private var weekStart: Date = .now
    @State private var showingDrawer = false
    @State private var pendingTarget: (day: Date, slot: MealSlot)? = nil
    @State private var showingClear = false

    private var settings: AppSettings { settingsList.first ?? AppSettings() }
    private var helper: WeekHelper { WeekHelper(weekStartsMonday: settings.weekStartsMonday) }
    private var days: [Date] { helper.days(from: helper.startOfWeek(containing: weekStart)) }

    private func meals(on day: Date, slot: MealSlot) -> [PlannedMeal] {
        meals.filter { helper.isSameDay($0.day, day) && $0.slot == slot }
    }

    private var plannedCountThisWeek: Int {
        let set = Set(days.map { helper.startOfDay($0) })
        return meals.filter { set.contains(helper.startOfDay($0.day)) }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                if recipes.isEmpty {
                    EmptyStateView(
                        icon: "calendar.badge.exclamationmark",
                        title: "No recipes to plan",
                        message: "Add a few recipes first, then drop them onto your week here."
                    )
                } else {
                    content
                }
            }
            .navigationTitle("This Week")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { changeWeek(-1) } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("Previous week")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { withAnimation { weekStart = .now } } label: {
                            Label("Jump to today", systemImage: "calendar.circle")
                        }
                        Button(role: .destructive) { showingClear = true } label: {
                            Label("Clear this week", systemImage: "trash")
                        }
                        .disabled(plannedCountThisWeek == 0)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Week options")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { changeWeek(1) } label: { Image(systemName: "chevron.right") }
                        .accessibilityLabel("Next week")
                }
            }
            .sheet(isPresented: $showingDrawer) {
                RecipePickerSheet { recipe in
                    if let target = pendingTarget {
                        addToPlan(recipe, day: target.day, slot: target.slot)
                    }
                }
            }
            .alert("Clear this week?", isPresented: $showingClear) {
                Button("Clear", role: .destructive) {
                    PlanStore(context: context).clearWeek(days: days)
                    regenerate()
                    Haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes all \(plannedCountThisWeek) planned meals this week. Recipes are kept.")
            }
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            weekHeader
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(days, id: \.self) { day in
                        DayCard(
                            day: day,
                            isToday: helper.isSameDay(day, .now),
                            mealsFor: { meals(on: day, slot: $0) },
                            onTapAdd: { slot in
                                pendingTarget = (day, slot)
                                Haptics.tap()
                                showingDrawer = true
                            },
                            onDrop: { recipe, slot in
                                addToPlan(recipe, day: day, slot: slot)
                            },
                            onRemove: { meal in
                                PlanStore(context: context).remove(meal)
                                regenerate()
                                Haptics.selection()
                            }
                        )
                    }
                }
                .padding()
                .padding(.bottom, 120)
            }
        }
        .overlay(alignment: .bottom) { recipeDrawer }
    }

    private var weekHeader: some View {
        let start = days.first ?? weekStart
        let end = days.last ?? weekStart
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(WeekHelper.weekRange.string(from: start)) – \(WeekHelper.weekRange.string(from: end))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                Text("\(plannedCountThisWeek) meals planned")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Text("Drag a recipe up")
                .font(.caption2)
                .foregroundStyle(Theme.secondaryText)
            Image(systemName: "hand.draw")
                .font(.caption)
                .foregroundStyle(Theme.terracotta)
                .accessibilityHidden(true)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    /// Horizontal drawer of draggable recipe chips at the bottom of the plan.
    private var recipeDrawer: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Recipes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Text("Drag onto a meal, or tap + on a slot")
                    .font(.caption2)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recipes) { recipe in
                        DraggableRecipeChip(recipe: recipe)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
        }
        .padding(.top, 8)
        .background(.ultraThinMaterial)
        .overlay(Theme.hairline.frame(height: 1), alignment: .top)
    }

    // MARK: - Actions

    private func changeWeek(_ delta: Int) {
        if let d = Calendar.current.date(byAdding: .day, value: delta * 7, to: helper.startOfWeek(containing: weekStart)) {
            withAnimation { weekStart = d }
            Haptics.selection()
        }
    }

    private func addToPlan(_ recipe: Recipe, day: Date, slot: MealSlot) {
        PlanStore(context: context).assign(
            recipe: recipe, to: day, slot: slot, servings: settings.defaultServings
        )
        regenerate()
        Haptics.success()
    }

    private func regenerate() {
        PlanStore(context: context).regenerateGroceryList(from: meals)
    }
}
