import SwiftUI
import SwiftData

struct LogFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var defaultMealType: MealType = .breakfast
    var prefillFood: FoodItem? = nil

    @State private var foodName: String = ""
    @State private var selectedMealType: MealType = .breakfast
    @State private var selectedPortion: PortionSize = .medium
    @State private var notes: String = ""
    @State private var allergenTags: [String] = []
    @State private var logDate: Date = Date()
    @State private var showingFoodPicker = false
    @State private var searchQuery = ""

    @Query private var settings: [NourishSettings]
    private var hapticsEnabled: Bool { settings.first?.hapticsEnabled ?? true }

    var body: some View {
        NavigationStack {
            ZStack {
                NourishTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: NourishTheme.Spacing.lg) {
                        // Food name input
                        foodNameSection

                        // Quick pick from catalog
                        quickPickSection

                        // Meal type
                        mealTypeSection

                        // Portion size
                        portionSection

                        // Allergen tags
                        allergenSection

                        // Date/time
                        dateSection

                        // Notes
                        notesSection

                        // Save button
                        Button(action: save) {
                            Text("Log Food")
                        }
                        .primaryButton()
                        .disabled(foodName.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.horizontal, NourishTheme.Spacing.md)
                    }
                    .padding(.vertical, NourishTheme.Spacing.md)
                }
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(NourishTheme.Colors.sage)
                }
            }
            .onAppear {
                selectedMealType = defaultMealType
                logDate = mealDate(for: defaultMealType)
                if let food = prefillFood {
                    foodName = food.name
                    allergenTags = food.allergenTags
                }
            }
        }
    }

    // MARK: - Sections

    private var foodNameSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.xs) {
            Label("Food Name", systemImage: "fork.knife")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            TextField("e.g., Scrambled Eggs, Brown Rice...", text: $foodName)
                .font(NourishTheme.Typography.body)
                .foregroundColor(NourishTheme.Colors.text)
                .padding(NourishTheme.Spacing.md)
                .background(NourishTheme.Colors.cardBackground)
                .cornerRadius(NourishTheme.CornerRadius.md)
                .shadow(
                    color: NourishTheme.Shadow.card.color,
                    radius: NourishTheme.Shadow.card.radius
                )
                .padding(.horizontal, NourishTheme.Spacing.md)
                .onChange(of: foodName) { _, newValue in
                    // Auto-fill allergen tags from catalog
                    if allergenTags.isEmpty {
                        let tags = FoodCatalog.allergenTags(for: newValue)
                        if !tags.isEmpty { allergenTags = tags }
                    }
                }
        }
    }

    private var quickPickSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Quick Pick from Library")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NourishTheme.Spacing.sm) {
                    ForEach(FoodCatalog.safe.prefix(8)) { food in
                        QuickPickChip(food: food, isSelected: foodName == food.name) {
                            foodName = food.name
                            allergenTags = food.allergenTags
                        }
                    }
                }
                .padding(.horizontal, NourishTheme.Spacing.md)
            }
        }
    }

    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Meal")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            HStack(spacing: NourishTheme.Spacing.sm) {
                ForEach(MealType.allCases) { meal in
                    Button(action: {
                        selectedMealType = meal
                        logDate = mealDate(for: meal)
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: meal.icon)
                                .font(.title3)
                                .foregroundColor(selectedMealType == meal ? .white : NourishTheme.Colors.sage)
                                .accessibilityHidden(true)
                            Text(meal.displayName)
                                .font(NourishTheme.Typography.caption)
                                .foregroundColor(selectedMealType == meal ? .white : NourishTheme.Colors.text)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NourishTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: NourishTheme.CornerRadius.sm)
                                .fill(selectedMealType == meal ? NourishTheme.Colors.sage : NourishTheme.Colors.cardBackground)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(meal.displayName)
                    .accessibilityAddTraits(selectedMealType == meal ? .isSelected : [])
                }
            }
            .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var portionSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Portion Size")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            HStack(spacing: NourishTheme.Spacing.sm) {
                ForEach(PortionSize.allCases) { portion in
                    Button(action: { selectedPortion = portion }) {
                        Text(portion.displayName)
                            .font(NourishTheme.Typography.callout)
                            .foregroundColor(selectedPortion == portion ? .white : NourishTheme.Colors.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, NourishTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: NourishTheme.CornerRadius.sm)
                                    .fill(selectedPortion == portion ? NourishTheme.Colors.sage : NourishTheme.Colors.cardBackground)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(portion.displayName) portion")
                    .accessibilityAddTraits(selectedPortion == portion ? .isSelected : [])
                }
            }
            .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var allergenSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Allergen Tags")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            let allergenOptions = ["gluten", "dairy", "eggs", "nuts", "soy", "corn", "nightshades"]
            FlowLayout(spacing: NourishTheme.Spacing.xs) {
                ForEach(allergenOptions, id: \.self) { allergen in
                    Button(action: {
                        if allergenTags.contains(allergen) {
                            allergenTags.removeAll { $0 == allergen }
                        } else {
                            allergenTags.append(allergen)
                        }
                    }) {
                        Text(allergen.capitalized)
                            .font(NourishTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(allergenTags.contains(allergen) ? .white : NourishTheme.Colors.text)
                            .padding(.horizontal, NourishTheme.Spacing.sm)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(allergenTags.contains(allergen) ? NourishTheme.Colors.allergenColor(for: allergen) : NourishTheme.Colors.cardBackground)
                                    .shadow(
                                        color: NourishTheme.Shadow.card.color,
                                        radius: 4
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(allergen) allergen")
                    .accessibilityAddTraits(allergenTags.contains(allergen) ? .isSelected : [])
                }
            }
            .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Time")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            DatePicker("Log time", selection: $logDate, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .padding(NourishTheme.Spacing.md)
                .background(NourishTheme.Colors.cardBackground)
                .cornerRadius(NourishTheme.CornerRadius.md)
                .shadow(color: NourishTheme.Shadow.card.color, radius: NourishTheme.Shadow.card.radius)
                .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: NourishTheme.Spacing.sm) {
            Text("Notes (optional)")
                .font(NourishTheme.Typography.subheadline)
                .foregroundColor(NourishTheme.Colors.secondaryText)
                .padding(.horizontal, NourishTheme.Spacing.md)

            TextField("Brand, preparation, etc.", text: $notes, axis: .vertical)
                .font(NourishTheme.Typography.body)
                .foregroundColor(NourishTheme.Colors.text)
                .lineLimit(3, reservesSpace: true)
                .padding(NourishTheme.Spacing.md)
                .background(NourishTheme.Colors.cardBackground)
                .cornerRadius(NourishTheme.CornerRadius.md)
                .shadow(color: NourishTheme.Shadow.card.color, radius: NourishTheme.Shadow.card.radius)
                .padding(.horizontal, NourishTheme.Spacing.md)
        }
    }

    // MARK: - Actions

    private func mealDate(for mealType: MealType) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(bySettingHour: mealType.defaultHour, minute: 0, second: 0, of: today) ?? Date()
    }

    private func save() {
        let trimmedName = foodName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let entry = FoodLogEntry(
            date: logDate,
            foodName: trimmedName,
            mealType: selectedMealType.rawValue,
            portionNote: selectedPortion.rawValue,
            notes: notes.trimmingCharacters(in: .whitespaces),
            allergenTags: allergenTags
        )
        modelContext.insert(entry)

        if hapticsEnabled {
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()
        }

        dismiss()
    }
}

// MARK: - QuickPickChip

private struct QuickPickChip: View {
    let food: FoodItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(food.name)
                .font(NourishTheme.Typography.caption)
                .foregroundColor(isSelected ? .white : NourishTheme.Colors.text)
                .padding(.horizontal, NourishTheme.Spacing.sm)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? NourishTheme.Colors.sage : NourishTheme.Colors.cardBackground)
                        .shadow(color: NourishTheme.Shadow.card.color, radius: 4)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? UIScreen.main.bounds.width
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width + spacing > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentRowWidth += size.width + spacing
        }

        let totalHeight = rows.reduce(CGFloat(0)) { acc, row in
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            return acc + rowHeight + spacing
        }
        return CGSize(width: maxWidth, height: max(0, totalHeight - spacing))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rows: [[LayoutSubviews.Element]] = [[]]
        var currentRowWidth: CGFloat = 0
        let maxWidth = bounds.width

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width + spacing > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(subview)
            currentRowWidth += size.width + spacing
        }

        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
}
