import SwiftUI
import SwiftData

struct GoalView: View {
    @Query private var goals: [UserGoal]

    private var goal: UserGoal? { goals.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                if let goal = goal {
                    GoalFormView(goal: goal)
                } else {
                    ProgressView("Loading…")
                        .tint(Brand.magic)
                }
            }
            .navigationTitle("Goal")
        }
    }
}

// MARK: - Goal form

private struct GoalFormView: View {
    @Bindable var goal: UserGoal
    @Environment(\.modelContext) private var ctx
    @AppStorage("plate.units") private var imperialUnits = false

    @State private var sex: Sex
    @State private var age: Int
    @State private var heightCm: Double
    @State private var weightKg: Double
    @State private var activity: Activity
    @State private var objective: Objective
    @State private var useManual: Bool

    // Manual targets
    @State private var manualCalories: Double
    @State private var manualProtein: Double
    @State private var manualCarbs: Double
    @State private var manualFat: Double

    // Entry text fields
    @State private var heightText: String
    @State private var weightText: String
    @State private var ageText: String
    @State private var calText: String
    @State private var proText: String
    @State private var carbText: String
    @State private var fatText: String

    @State private var saveSuccess = false
    @State private var validationError = ""

    init(goal: UserGoal) {
        _goal = Bindable(wrappedValue: goal)
        _sex = State(initialValue: goal.sex)
        _age = State(initialValue: goal.age)
        _heightCm = State(initialValue: goal.heightCm)
        _weightKg = State(initialValue: goal.weightKg)
        _activity = State(initialValue: goal.activity)
        _objective = State(initialValue: goal.objective)
        _useManual = State(initialValue: goal.useManualTargets)
        _manualCalories = State(initialValue: goal.calorieTarget)
        _manualProtein  = State(initialValue: goal.proteinTarget)
        _manualCarbs    = State(initialValue: goal.carbTarget)
        _manualFat      = State(initialValue: goal.fatTarget)
        _heightText = State(initialValue: String(format: "%.0f", goal.heightCm))
        _weightText = State(initialValue: String(format: "%.1f", goal.weightKg))
        _ageText    = State(initialValue: "\(goal.age)")
        _calText    = State(initialValue: "\(Int(goal.calorieTarget))")
        _proText    = State(initialValue: "\(Int(goal.proteinTarget))")
        _carbText   = State(initialValue: "\(Int(goal.carbTarget))")
        _fatText    = State(initialValue: "\(Int(goal.fatTarget))")
    }

    // Computed live targets from current form state
    private var computedTargets: MacroTargets {
        let tempGoal = UserGoal(
            calorieTarget: manualCalories,
            proteinTarget: manualProtein,
            carbTarget: manualCarbs,
            fatTarget: manualFat,
            sex: sex,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            activity: activity,
            objective: objective,
            useManualTargets: false
        )
        let cal = NutritionEngine.targetCalories(goal: tempGoal)
        return NutritionEngine.macroTargets(calories: cal, weightKg: weightKg, objective: objective)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if saveSuccess {
                    successBanner
                }

                if !validationError.isEmpty {
                    errorBanner
                }

                // Current targets display
                targetsCard

                // Stats form
                statsCard

                // Manual override
                manualOverrideCard

                saveButton
            }
            .padding(16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Sub-cards

    private var targetsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: useManual ? "Manual Targets" : "Computed Targets")
                Text("Daily Goals")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)

                let targets = useManual
                    ? MacroTargets(calories: manualCalories, protein: manualProtein, carbs: manualCarbs, fat: manualFat)
                    : computedTargets

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    targetCell(label: "Calories", value: Format.kcalShort(targets.calories), unit: "kcal", color: Brand.magic)
                    targetCell(label: "Protein",  value: Format.grams(targets.protein),  unit: "per day", color: Brand.danger)
                    targetCell(label: "Carbs",    value: Format.grams(targets.carbs),    unit: "per day", color: Brand.warn)
                    targetCell(label: "Fat",      value: Format.grams(targets.fat),      unit: "per day", color: Brand.info)
                }
            }
        }
    }

    private func targetCell(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.text3)
            Text(value)
                .font(Brand.mono(20, weight: .semibold))
                .foregroundStyle(color)
            Text(unit)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value)")
    }

    private var statsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Eyebrow(text: "Your Stats")
                Text("Profile")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Brand.text)

                VStack(spacing: 12) {
                    // Sex picker
                    HStack {
                        Text("Biological Sex")
                            .foregroundStyle(Brand.text2)
                            .font(.subheadline)
                        Spacer()
                        Picker("Sex", selection: $sex) {
                            ForEach(Sex.allCases, id: \.self) { s in
                                Text(s.displayName).tag(s)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Brand.magic)
                    }

                    Divider().background(Brand.hairline)

                    // Age
                    formRow(label: "Age (years)", text: $ageText) { val in
                        if let i = Int(val), i >= 10, i <= 120 { age = i }
                    }

                    Divider().background(Brand.hairline)

                    // Height
                    formRow(
                        label: imperialUnits ? "Height (in)" : "Height (cm)",
                        text: $heightText
                    ) { val in
                        if let d = Double(val), d > 0 {
                            heightCm = imperialUnits ? d * 2.54 : d
                        }
                    }

                    Divider().background(Brand.hairline)

                    // Weight
                    formRow(
                        label: imperialUnits ? "Weight (lbs)" : "Weight (kg)",
                        text: $weightText
                    ) { val in
                        if let d = Double(val), d > 0 {
                            weightKg = imperialUnits ? d / 2.20462 : d
                        }
                    }

                    Divider().background(Brand.hairline)

                    // Activity
                    HStack {
                        Text("Activity Level")
                            .foregroundStyle(Brand.text2)
                            .font(.subheadline)
                        Spacer()
                        Picker("Activity", selection: $activity) {
                            ForEach(Activity.allCases, id: \.self) { a in
                                Text(a.displayName).tag(a)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Brand.magic)
                    }

                    Divider().background(Brand.hairline)

                    // Objective
                    HStack {
                        Text("Objective")
                            .foregroundStyle(Brand.text2)
                            .font(.subheadline)
                        Spacer()
                        Picker("Objective", selection: $objective) {
                            ForEach(Objective.allCases, id: \.self) { o in
                                Text(o.displayName).tag(o)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Brand.magic)
                    }
                }
            }
        }
    }

    private func formRow(label: String, text: Binding<String>, onCommit: @escaping (String) -> Void) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Brand.text2)
                .font(.subheadline)
            Spacer()
            TextField("", text: text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .foregroundStyle(Brand.text)
                .frame(maxWidth: 100)
                .onChange(of: text.wrappedValue) { _, val in
                    onCommit(val)
                }
        }
    }

    private var manualOverrideCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $useManual) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manual Targets")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                        Text("Override computed values")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                }
                .tint(Brand.magic)
                .accessibilityLabel("Use manual targets")
                .accessibilityHint("When enabled you set calorie and macro targets directly")

                if useManual {
                    Divider().background(Brand.hairline)

                    VStack(spacing: 10) {
                        manualRow(label: "Calories (kcal)", text: $calText) { val in
                            if let d = Double(val), d >= 0 { manualCalories = d }
                        }
                        manualRow(label: "Protein (g)", text: $proText) { val in
                            if let d = Double(val), d >= 0 { manualProtein = d }
                        }
                        manualRow(label: "Carbs (g)", text: $carbText) { val in
                            if let d = Double(val), d >= 0 { manualCarbs = d }
                        }
                        manualRow(label: "Fat (g)", text: $fatText) { val in
                            if let d = Double(val), d >= 0 { manualFat = d }
                        }
                    }
                }
            }
        }
    }

    private func manualRow(label: String, text: Binding<String>, onCommit: @escaping (String) -> Void) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Brand.text2)
                .font(.subheadline)
            Spacer()
            TextField("0", text: text)
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .foregroundStyle(Brand.text)
                .frame(maxWidth: 100)
                .onChange(of: text.wrappedValue) { _, val in onCommit(val) }
        }
    }

    private var saveButton: some View {
        Button("Save Goal") {
            saveGoal()
        }
        .buttonStyle(InkButtonStyle())
    }

    private var successBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Brand.live)
                .accessibilityHidden(true)
            Text("Goal saved successfully.")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.live)
            Spacer()
        }
        .padding(12)
        .background(Brand.live.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var errorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Brand.danger)
                .accessibilityHidden(true)
            Text(validationError)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.danger)
            Spacer()
        }
        .padding(12)
        .background(Brand.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private func saveGoal() {
        validationError = ""

        guard age >= 10, age <= 120 else {
            validationError = "Age must be between 10 and 120."
            return
        }
        guard heightCm > 50, heightCm < 280 else {
            validationError = imperialUnits ? "Height must be between 20 and 110 inches." : "Height must be between 50 and 280 cm."
            return
        }
        guard weightKg > 20, weightKg < 500 else {
            validationError = imperialUnits ? "Weight must be between 44 and 1102 lbs." : "Weight must be between 20 and 500 kg."
            return
        }
        if useManual {
            guard manualCalories >= 800 else {
                validationError = "Calorie target must be at least 800 kcal."
                return
            }
            guard manualProtein >= 0, manualCarbs >= 0, manualFat >= 0 else {
                validationError = "Macro values must be 0 or greater."
                return
            }
        }

        goal.sex = sex
        goal.age = age
        goal.heightCm = heightCm
        goal.weightKg = weightKg
        goal.activity = activity
        goal.objective = objective
        goal.useManualTargets = useManual

        if useManual {
            goal.calorieTarget = manualCalories
            goal.proteinTarget = manualProtein
            goal.carbTarget    = manualCarbs
            goal.fatTarget     = manualFat
        } else {
            NutritionEngine.recompute(into: goal)
        }

        try? ctx.save()
        Haptics.success()
        saveSuccess = true

        // Auto-clear success banner
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(Brand.ease(0.3)) {
                saveSuccess = false
            }
        }
    }
}
