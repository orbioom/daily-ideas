import SwiftUI
import SwiftData

struct DiaryView: View {
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var addFoodMeal: Meal? = nil
    @State private var editEntry: DiaryEntry? = nil

    @Query private var goals: [UserGoal]
    @Environment(\.modelContext) private var ctx
    @AppStorage("plate.showMacros") private var showMacros = true

    private var goal: UserGoal? { goals.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 0) {
                        DateStripView(selectedDate: $selectedDate)
                            .padding(.bottom, 12)

                        DiaryDaySummaryCard(date: selectedDate, goal: goal)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)

                        DiaryMealSections(
                            date: selectedDate,
                            onAdd: { meal in addFoodMeal = meal },
                            onEdit: { entry in editEntry = entry }
                        )
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(Format.dayHeader(selectedDate))
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $addFoodMeal) { meal in
            AddFoodFlow(meal: meal, date: selectedDate)
        }
        .sheet(item: $editEntry) { entry in
            EditEntryView(entry: entry)
        }
    }
}

// MARK: - Day summary card

private struct DiaryDaySummaryCard: View {
    let date: Date
    let goal: UserGoal?

    @Query private var allEntries: [DiaryEntry]

    private var entries: [DiaryEntry] {
        let cal = Calendar.current
        return allEntries.filter { cal.isDate($0.day, inSameDayAs: date) }
    }

    private var totals: DayTotals { NutritionEngine.dayTotals(entries) }
    private var calTarget: Double { goal?.calorieTarget ?? 2000 }
    private var proteinTarget: Double { goal?.proteinTarget ?? 150 }
    private var carbTarget: Double { goal?.carbTarget ?? 225 }
    private var fatTarget: Double { goal?.fatTarget ?? 60 }

    var body: some View {
        GlassCard {
            VStack(spacing: 20) {
                HStack(alignment: .center, spacing: 24) {
                    RingGauge(consumed: totals.calories, target: calTarget)

                    VStack(alignment: .leading, spacing: 8) {
                        statRow(label: "Eaten",  value: Format.kcal(totals.calories), color: Brand.magic)
                        statRow(label: "Target", value: Format.kcal(calTarget),       color: Brand.text2)
                        let rem = NutritionEngine.remaining(target: calTarget, consumed: totals.calories)
                        statRow(
                            label: rem >= 0 ? "Left" : "Over",
                            value: Format.kcal(abs(rem)),
                            color: rem >= 0 ? Brand.live : Brand.danger
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider().background(Brand.hairline)

                VStack(spacing: 10) {
                    MacroBar(label: "Protein", consumed: totals.protein, target: proteinTarget, color: Brand.danger)
                    MacroBar(label: "Carbs",   consumed: totals.carbs,   target: carbTarget,   color: Brand.warn)
                    MacroBar(label: "Fat",     consumed: totals.fat,     target: fatTarget,    color: Brand.info)
                }
            }
        }
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
            Spacer()
            Text(value)
                .font(Brand.mono(13, weight: .medium))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Meal sections

private struct DiaryMealSections: View {
    let date: Date
    var onAdd: (Meal) -> Void
    var onEdit: (DiaryEntry) -> Void

    @Query private var allEntries: [DiaryEntry]
    @Environment(\.modelContext) private var ctx

    private var dayEntries: [DiaryEntry] {
        let cal = Calendar.current
        return allEntries.filter { cal.isDate($0.day, inSameDayAs: date) }
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Meal.allCases) { meal in
                let mealEntries = dayEntries
                    .filter { $0.meal == meal }
                    .sorted { $0.createdAt < $1.createdAt }
                MealSection(
                    meal: meal,
                    entries: mealEntries,
                    onAdd: { onAdd(meal) },
                    onEdit: onEdit,
                    onDelete: { entry in
                        Haptics.warning()
                        ctx.delete(entry)
                        try? ctx.save()
                    }
                )
            }
        }
    }
}

private struct MealSection: View {
    let meal: Meal
    let entries: [DiaryEntry]
    var onAdd: () -> Void
    var onEdit: (DiaryEntry) -> Void
    var onDelete: (DiaryEntry) -> Void

    private var subtotal: Double { entries.reduce(0) { $0 + $1.calories } }

    var body: some View {
        VStack(spacing: 0) {
            mealHeader

            if entries.isEmpty {
                emptyRow
            } else {
                entriesWithAddMore
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: Brand.cardShadow, radius: 8, x: 0, y: 4)
    }

    private var mealHeader: some View {
        HStack {
            Image(systemName: meal.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Brand.magic)
                .accessibilityHidden(true)
            Text(meal.displayName)
                .font(.headline)
                .foregroundStyle(Brand.text)
            Spacer()
            if subtotal > 0 {
                Text("\(Format.kcalShort(subtotal)) kcal")
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(subtotal > 0
            ? "\(meal.displayName), \(Format.kcal(subtotal))"
            : meal.displayName)
    }

    private var emptyRow: some View {
        Button(action: onAdd) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                Text("Add food")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.ultraThinMaterial)
        .accessibilityLabel("Add food to \(meal.displayName)")
    }

    private var entriesWithAddMore: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { idx, entry in
                entryRow(entry: entry, isLast: idx == entries.count - 1)
            }
            Divider().padding(.horizontal, 16)
            addMoreRow
        }
        .background(.ultraThinMaterial)
    }

    private func entryRow(entry: DiaryEntry, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                DiaryEntryRow(entry: entry)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Haptics.tap()
                        onEdit(entry)
                    }

                Spacer(minLength: 0)

                Button {
                    onDelete(entry)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(Brand.danger)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .accessibilityLabel("Delete \(entry.foodName) from \(meal.displayName)")
            }
            if !isLast {
                Divider().padding(.leading, 16)
            }
        }
    }

    private var addMoreRow: some View {
        Button(action: onAdd) {
            HStack {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Brand.magic)
                    .accessibilityHidden(true)
                Text("Add more")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text3)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .accessibilityLabel("Add more food to \(meal.displayName)")
    }
}

// MARK: - Edit entry sheet

struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    let entry: DiaryEntry

    @State private var servings: Double
    @State private var servingText: String

    init(entry: DiaryEntry) {
        self.entry = entry
        _servings    = State(initialValue: entry.servings)
        _servingText = State(initialValue: Format.servings(entry.servings))
    }

    // Per-serving baseline derived from entry snapshot
    private var perServingCal:  Double { entry.servings > 0 ? entry.calories / entry.servings : 0 }
    private var perServingPro:  Double { entry.servings > 0 ? entry.protein  / entry.servings : 0 }
    private var perServingCarb: Double { entry.servings > 0 ? entry.carbs    / entry.servings : 0 }
    private var perServingFat:  Double { entry.servings > 0 ? entry.fat      / entry.servings : 0 }

    private var computedCal:  Double { perServingCal  * servings }
    private var computedPro:  Double { perServingPro  * servings }
    private var computedCarb: Double { perServingCarb * servings }
    private var computedFat:  Double { perServingFat  * servings }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Eyebrow(text: entry.meal.displayName)
                                Text(entry.foodName)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Brand.text)
                                Text(entry.servingDesc)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text3)
                            }
                        }

                        GlassCard {
                            VStack(spacing: 16) {
                                Eyebrow(text: "Servings")

                                HStack(spacing: 16) {
                                    Button {
                                        let newVal = max(0.25, servings - 0.25)
                                        servings = newVal
                                        servingText = Format.servings(newVal)
                                        Haptics.selection()
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(Brand.text2)
                                    }
                                    .accessibilityLabel("Decrease servings")

                                    TextField("Servings", text: $servingText)
                                        .font(Brand.mono(28, weight: .semibold))
                                        .foregroundStyle(Brand.text)
                                        .multilineTextAlignment(.center)
                                        .keyboardType(.decimalPad)
                                        .frame(maxWidth: 100)
                                        .onChange(of: servingText) { _, val in
                                            if let d = Double(val), d > 0 { servings = d }
                                        }

                                    Button {
                                        let newVal = servings + 0.25
                                        servings = newVal
                                        servingText = Format.servings(newVal)
                                        Haptics.selection()
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(Brand.magic)
                                    }
                                    .accessibilityLabel("Increase servings")
                                }
                            }
                        }

                        GlassCard {
                            HStack {
                                macroCell(label: "Calories", value: Format.kcalShort(computedCal), color: Brand.magic)
                                Divider().frame(height: 40)
                                macroCell(label: "Protein",  value: Format.grams(computedPro),  color: Brand.danger)
                                Divider().frame(height: 40)
                                macroCell(label: "Carbs",    value: Format.grams(computedCarb), color: Brand.warn)
                                Divider().frame(height: 40)
                                macroCell(label: "Fat",      value: Format.grams(computedFat),  color: Brand.info)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("Nutrition preview: \(Format.kcal(computedCal)), protein \(Format.grams(computedPro)), carbs \(Format.grams(computedCarb)), fat \(Format.grams(computedFat))")
                        }

                        Button("Save") {
                            guard servings > 0 else { return }
                            entry.servings = servings
                            entry.calories = computedCal
                            entry.protein  = computedPro
                            entry.carbs    = computedCarb
                            entry.fat      = computedFat
                            try? ctx.save()
                            Haptics.success()
                            dismiss()
                        }
                        .buttonStyle(InkButtonStyle())
                        .disabled(servings <= 0)

                        Button("Delete Entry", role: .destructive) {
                            ctx.delete(entry)
                            try? ctx.save()
                            Haptics.warning()
                            dismiss()
                        }
                        .foregroundStyle(Brand.danger)
                        .font(.subheadline)
                        .accessibilityLabel("Delete this diary entry")
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Brand.text2)
                }
            }
        }
    }

    private func macroCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }
}
