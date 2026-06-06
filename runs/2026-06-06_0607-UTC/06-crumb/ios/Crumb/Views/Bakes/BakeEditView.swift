import SwiftUI
import SwiftData

/// Create or edit a bake's plan: formula, target weight, loaf count, scheduling anchor,
/// and direction (forward from start / backward from finish). New bakes seed a sensible
/// default timeline the baker can refine in the detail view.
struct BakeEditView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Formula.createdAt, order: .reverse) private var formulas: [Formula]

    var bake: Bake?

    @State private var title: String = ""
    @State private var selectedFormula: Formula?
    @State private var targetDough: Double = 900
    @State private var loafCount: Int = 1
    @State private var fromFinish: Bool = false
    @State private var anchor: Date = .now
    @State private var loaded = false

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedTitle.isEmpty && selectedFormula != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bake") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)
                    Picker("Formula", selection: $selectedFormula) {
                        Text("Choose…").tag(Formula?.none)
                        ForEach(formulas) { formula in
                            Text(formula.name).tag(Formula?.some(formula))
                        }
                    }
                }

                Section {
                    HStack {
                        Text("Total dough")
                        Spacer()
                        Text(Units.massWithSuffix(targetDough, unit: settings.massUnit))
                            .font(Brand.mono(15))
                            .foregroundStyle(Brand.text2)
                            .monospacedDigit()
                    }
                    Slider(value: $targetDough, in: 100...5000, step: 25)
                        .tint(Brand.text)
                        .accessibilityLabel("Total dough")
                        .accessibilityValue(Units.massWithSuffix(targetDough, unit: settings.massUnit))
                    Stepper(value: $loafCount, in: 1...24) {
                        HStack {
                            Text("Loaves")
                            Spacer()
                            Text("\(loafCount) · \(Units.massWithSuffix(BakersMath.gramsPerLoaf(totalDough: targetDough, loafCount: loafCount), unit: settings.massUnit)) each")
                                .font(Brand.mono(14))
                                .foregroundStyle(Brand.text3)
                                .monospacedDigit()
                        }
                    }
                } header: {
                    Text("Yield")
                }

                Section {
                    Picker("Schedule", selection: $fromFinish) {
                        Text("From start").tag(false)
                        Text("To finish").tag(true)
                    }
                    .pickerStyle(.segmented)
                    DatePicker(fromFinish ? "Out of oven by" : "Start at",
                               selection: $anchor)
                } header: {
                    Text("Timeline")
                } footer: {
                    Text(fromFinish
                         ? "Steps are scheduled backward so the bake finishes at this time."
                         : "Steps are scheduled forward from this start time.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Brand.pageBackground)
            .navigationTitle(bake == nil ? "New Bake" : "Edit Bake")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if let bake {
            title = bake.title
            selectedFormula = bake.formula
            targetDough = bake.targetDoughGrams
            loafCount = max(1, bake.loafCount)
            fromFinish = bake.schedulesFromFinish
            anchor = bake.anchorTime
        } else {
            targetDough = settings.defaultDoughGrams
            fromFinish = settings.schedulesFromFinish
            selectedFormula = formulas.first
            anchor = defaultAnchor()
        }
    }

    /// A pleasant default anchor: forward bakes start now; finish bakes target this
    /// evening (or tomorrow evening if it's already late).
    private func defaultAnchor() -> Date {
        let cal = Calendar.current
        if settings.schedulesFromFinish {
            let base = cal.date(bySettingHour: 18, minute: 0, second: 0, of: .now) ?? .now
            return base > .now ? base : (cal.date(byAdding: .day, value: 1, to: base) ?? base)
        }
        return .now
    }

    private func save() {
        guard canSave, let formula = selectedFormula else { return }
        let target: Bake
        if let bake {
            target = bake
            target.title = trimmedTitle
            target.formula = formula
            target.targetDoughGrams = targetDough
            target.loafCount = max(1, loafCount)
            target.schedulesFromFinish = fromFinish
            target.anchorTime = anchor
        } else {
            target = Bake(title: trimmedTitle,
                          date: anchor,
                          anchorTime: anchor,
                          schedulesFromFinish: fromFinish,
                          targetDoughGrams: targetDough,
                          loafCount: max(1, loafCount))
            target.formula = formula
            context.insert(target)
            seedSteps(for: target, style: formula.style)
        }
        Haptics.success(enabled: settings.hapticsEnabled)
        dismiss()
    }

    /// Seed a default timeline appropriate to the formula's style so a new bake is
    /// immediately useful; the baker tunes durations in the detail view.
    private func seedSteps(for bake: Bake, style: Style) {
        let plan: [(StepKind, Int)]
        switch style {
        case .baguette:
            plan = [(.autolyse, 40), (.mix, 15), (.bulk, 180), (.preshape, 20),
                    (.shape, 15), (.coldProof, 600), (.bake, 25), (.cool, 45)]
        case .focaccia:
            plan = [(.mix, 15), (.bulk, 240), (.proof, 120), (.bake, 25), (.cool, 30)]
        case .wholeGrain, .enriched:
            plan = [(.autolyse, 40), (.mix, 15), (.bulk, 210), (.shape, 15),
                    (.proof, 150), (.bake, 45), (.cool, 60)]
        case .sourdough, .other:
            plan = [(.autolyse, 45), (.mix, 15), (.bulk, 240), (.preshape, 20),
                    (.shape, 15), (.coldProof, 720), (.bake, 45), (.cool, 90)]
        }
        for (index, entry) in plan.enumerated() {
            let step = BakeStep(order: index, kind: entry.0, plannedMinutes: entry.1)
            step.bake = bake
            context.insert(step)
        }
    }
}
