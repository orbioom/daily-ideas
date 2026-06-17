import SwiftUI
import SwiftData

/// Plan: the profile & goal editor with a live target preview, safe-rate
/// warnings and a transparent BMR → TDEE → target breakdown. Saving writes the
/// profile and a TargetSnapshot.
struct PlanView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Profile.createdAt, order: .reverse) private var profiles: [Profile]

    @State private var model: PlanEditorModel?
    @State private var showSaved = false

    private var profile: Profile? { profiles.first }

    var body: some View {
        NavigationStack {
            Group {
                if let model {
                    editor(model: model)
                } else {
                    ProgressView().controlSize(.large)
                }
            }
            .fuelScreenBackground(scheme)
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear { ensureModel() }
    }

    private func ensureModel() {
        if model == nil {
            model = PlanEditorModel(profile: profile, defaultProteinPerKg: settings.proteinPerKg)
        }
    }

    @ViewBuilder
    private func editor(model: PlanEditorModel) -> some View {
        @Bindable var m = model
        let preview = m.preview(formula: settings.bmrFormula, roundTo: settings.roundTo)

        ScrollView {
            VStack(spacing: 16) {
                // Live preview card
                previewCard(preview)

                // Safe-rate / floor warnings
                if !preview.warnings.isEmpty {
                    WarningBanner(messages: preview.warnings)
                }

                // About you
                FuelCard {
                    VStack(alignment: .leading, spacing: 16) {
                        FuelSectionHeader(title: "About you", systemImage: "person.fill")

                        segmentedRow(title: "Sex") {
                            Picker("Sex", selection: $m.sex) {
                                ForEach(Sex.allCases) { Text($0.label).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }

                        StepperRow(title: "Age",
                                   value: Double(m.age),
                                   unit: "yrs",
                                   step: 1,
                                   range: 14...100,
                                   format: { "\(Int($0))" },
                                   onChange: { m.age = Int($0) })

                        HeightRow(heightCm: $m.heightCm, unit: settings.heightUnit)

                        WeightRow(title: "Current weight",
                                  weightKg: $m.currentWeightKg,
                                  unit: settings.weightUnit)

                        bodyFatRow(m: m)
                    }
                }

                // Activity
                FuelCard {
                    VStack(alignment: .leading, spacing: 12) {
                        FuelSectionHeader(title: "Activity", systemImage: "figure.run")
                        ForEach(ActivityLevel.allCases) { level in
                            SelectableRow(title: level.title,
                                          detail: level.detail,
                                          trailing: "×\(MacroEngine.format(level.multiplier))",
                                          selected: m.activity == level) {
                                m.activity = level
                                Haptics.tap(settings.hapticsEnabled)
                            }
                        }
                    }
                }

                // Goal
                FuelCard {
                    VStack(alignment: .leading, spacing: 16) {
                        FuelSectionHeader(title: "Goal", systemImage: "target")

                        Picker("Goal", selection: $m.goal) {
                            ForEach(Goal.allCases) { Text($0.title).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: m.goal) { _, newGoal in
                            // Clamp the rate into the new goal's sensible range.
                            if newGoal == .maintain { m.goalRatePercent = 0 }
                            else if m.goalRatePercent == 0 { m.goalRatePercent = newGoal == .bulk ? 0.25 : 0.5 }
                            m.goalRatePercent = min(m.goalRatePercent, m.maxRate)
                        }

                        if m.goal != .maintain {
                            rateSlider(m: m)
                        }

                        WeightRow(title: "Goal weight",
                                  weightKg: $m.goalWeightKg,
                                  unit: settings.weightUnit)
                    }
                }

                // Diet style + macro preview
                FuelCard {
                    VStack(alignment: .leading, spacing: 14) {
                        FuelSectionHeader(title: "Diet style", systemImage: "fork.knife")
                        ForEach(DietStyle.allCases) { style in
                            SelectableRow(title: style.title,
                                          detail: style.detail,
                                          trailing: nil,
                                          selected: m.dietStyle == style) {
                                m.dietStyle = style
                                Haptics.tap(settings.hapticsEnabled)
                            }
                        }
                        if m.dietStyle == .custom {
                            customMacroControls(m: m)
                        }
                        Divider().overlay(FuelTheme.hairline(scheme))
                        MacroBarsView(macros: preview.macros)
                    }
                }

                // Validation errors
                if !m.validationErrors.isEmpty {
                    WarningBanner(messages: m.validationErrors, tint: FuelTheme.danger)
                }

                // Save
                Button("Save plan & recompute") { save(m: m, preview: preview) }
                    .buttonStyle(FuelPrimaryButtonStyle())
                    .disabled(!m.isValid)
                    .opacity(m.isValid ? 1 : 0.6)
            }
            .padding(16)
        }
        .overlay(alignment: .bottom) {
            if showSaved {
                SavedToast()
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Subviews

    private func previewCard(_ preview: TargetResult) -> some View {
        FuelCard {
            VStack(spacing: 14) {
                CalorieRing(calories: preview.calorieTarget, fraction: 1.0, diameter: 170)
                // Transparent math breakdown
                VStack(spacing: 8) {
                    mathRow("BMR", "\(Fmt.kcal(preview.bmr)) kcal", FuelTheme.secondaryText(scheme))
                    mathRow("× Activity → TDEE", "\(Fmt.kcal(preview.maintenanceTDEE)) kcal", FuelTheme.secondaryText(scheme))
                    mathRow(preview.dailyDelta == 0 ? "No adjustment" : (preview.dailyDelta < 0 ? "− deficit" : "+ surplus"),
                            preview.dailyDelta == 0 ? "—" : "\(preview.dailyDelta < 0 ? "−" : "+")\(Fmt.kcal(abs(preview.dailyDelta))) kcal/day",
                            FuelTheme.secondaryText(scheme))
                    Divider().overlay(FuelTheme.hairline(scheme))
                    mathRow("Daily target", "\(Fmt.kcal(preview.calorieTarget)) kcal", FuelTheme.primaryText(scheme), bold: true)
                }
            }
        }
    }

    private func mathRow(_ label: String, _ value: String, _ color: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(bold ? .subheadline.weight(.bold) : .subheadline)
                .foregroundStyle(color)
            Spacer()
            Text(value)
                .font((bold ? .subheadline.weight(.bold) : .subheadline).monospacedDigit())
                .foregroundStyle(bold ? FuelTheme.primaryText(scheme) : color)
        }
        .accessibilityElement(children: .combine)
    }

    private func rateSlider(m: PlanEditorModel) -> some View {
        @Bindable var m = m
        let isHot = (m.goal == .cut && m.goalRatePercent > MacroEngine.safeCutRate)
            || (m.goal == .bulk && m.goalRatePercent > MacroEngine.safeBulkRate)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Rate")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FuelTheme.primaryText(scheme))
                Spacer()
                Text("\(Fmt.percent(m.goalRatePercent)) of bodyweight / week")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(isHot ? FuelTheme.warning : FuelTheme.orange)
            }
            Slider(value: $m.goalRatePercent, in: 0.1...m.maxRate, step: 0.05) {
                Text("Rate")
            }
            .tint(isHot ? FuelTheme.warning : FuelTheme.orange)
            .accessibilityValue("\(Fmt.percent(m.goalRatePercent)) per week")
            Text(isHot ? "Above the recommended safe rate." : "Within the recommended safe range.")
                .font(.caption2)
                .foregroundStyle(isHot ? FuelTheme.warning : FuelTheme.secondaryText(scheme))
        }
    }

    private func bodyFatRow(m: PlanEditorModel) -> some View {
        @Bindable var m = m
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Body fat")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FuelTheme.primaryText(scheme))
                Text("Optional — enables Katch-McArdle")
                    .font(.caption2)
                    .foregroundStyle(FuelTheme.secondaryText(scheme))
            }
            Spacer()
            TextField("%", text: $m.bodyFatText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(FuelTheme.subtleSurface(scheme)))
            Text("%")
                .font(.subheadline)
                .foregroundStyle(FuelTheme.secondaryText(scheme))
        }
    }

    private func customMacroControls(m: PlanEditorModel) -> some View {
        @Bindable var m = m
        return VStack(spacing: 12) {
            StepperRow(title: "Protein",
                       value: m.customProteinPerKg,
                       unit: "g/kg",
                       step: 0.1,
                       range: 0.8...3.0,
                       format: { String(format: "%.1f", $0) },
                       onChange: { m.customProteinPerKg = $0 })
            StepperRow(title: "Fat",
                       value: m.customFatPerKg,
                       unit: "g/kg",
                       step: 0.1,
                       range: 0.4...2.0,
                       format: { String(format: "%.1f", $0) },
                       onChange: { m.customFatPerKg = $0 })
        }
    }

    private func segmentedRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(FuelTheme.primaryText(scheme))
            content()
        }
    }

    // MARK: - Save

    private func save(m: PlanEditorModel, preview: TargetResult) {
        guard m.isValid else { return }
        let target: Profile
        if let existing = profile {
            target = existing
        } else {
            // Build a fresh profile; birthDate from age.
            let birth = Calendar.current.date(byAdding: .year, value: -m.age, to: Date()) ?? Date()
            let p = Profile(sex: m.sex,
                            birthDate: birth,
                            heightCm: m.heightCm,
                            startWeightKg: m.currentWeightKg,
                            currentWeightKg: m.currentWeightKg,
                            bodyFatPercent: m.bodyFatPercent,
                            activity: m.activity,
                            goal: m.goal,
                            goalRatePercent: m.goalRatePercent,
                            dietStyle: m.dietStyle,
                            customProteinPerKg: m.customProteinPerKg,
                            customFatPerKg: m.customFatPerKg,
                            goalWeightKg: m.goalWeightKg)
            modelContext.insert(p)
            target = p
        }

        // Update mutable fields.
        target.sex = m.sex
        if let birth = Calendar.current.date(byAdding: .year, value: -m.age, to: Date()) {
            target.birthDate = birth
        }
        target.heightCm = m.heightCm
        target.currentWeightKg = m.currentWeightKg
        target.bodyFatPercent = m.bodyFatPercent
        target.activity = m.activity
        target.goal = m.goal
        target.goalRatePercent = m.goal == .maintain ? 0 : m.goalRatePercent
        target.dietStyle = m.dietStyle
        target.customProteinPerKg = m.customProteinPerKg
        target.customFatPerKg = m.customFatPerKg
        target.goalWeightKg = m.goalWeightKg

        // Write a target snapshot logging this plan.
        let snap = TargetSnapshot(date: Date(),
                                  calorieTarget: preview.calorieTarget,
                                  proteinG: preview.macros.proteinG,
                                  carbG: preview.macros.carbG,
                                  fatG: preview.macros.fatG,
                                  estimatedTDEE: preview.maintenanceTDEE,
                                  rationale: "Plan saved: \(m.goal.title)\(m.goal == .maintain ? "" : " at \(Fmt.percent(m.goalRatePercent))/wk"), \(m.dietStyle.title).")
        modelContext.insert(snap)
        try? modelContext.save()

        Haptics.success(settings.hapticsEnabled)
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showSaved = false }
        }
    }
}

/// Brief success toast after saving.
private struct SavedToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
            Text("Plan saved")
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Capsule().fill(FuelTheme.positive))
        .accessibilityLabel("Plan saved")
    }
}
