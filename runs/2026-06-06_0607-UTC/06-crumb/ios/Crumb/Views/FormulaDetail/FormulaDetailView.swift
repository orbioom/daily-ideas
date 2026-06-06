import SwiftUI
import SwiftData

/// The live baker's-percentage scaler. The single source of truth is the formula's
/// percentages; the baker drives one of three controls — total dough weight, target
/// hydration, or loaf count — and every absolute figure recomputes instantly.
struct FormulaDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Bindable var formula: Formula

    // Live scaler inputs.
    @State private var totalDough: Double = 900
    @State private var loafCount: Int = 1
    @State private var hydrationTarget: Double = 0
    @State private var initialized = false

    @State private var editing = false
    @State private var showingExport = false
    @State private var exportURL: URL?

    /// Value-type rows for the engine, derived from the model.
    private var rows: [BakersMath.Row] {
        formula.orderedIngredients.map {
            BakersMath.Row(id: $0.id, name: $0.name, role: $0.role,
                           percent: $0.percent, levainHydration: $0.levainHydration)
        }
    }

    private var result: BakersMath.Result {
        BakersMath.solve(rows: rows, target: .totalDough(grams: totalDough))
    }

    private var gramsPerLoaf: Double {
        BakersMath.gramsPerLoaf(totalDough: totalDough, loafCount: loafCount)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if rows.isEmpty || !result.hasFlour {
                    noFlourGuidance
                } else {
                    headlineCard
                    scalerCard
                    ingredientsCard
                }
                bakesLink
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle(formula.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editing = true } label: { Label("Edit formula", systemImage: "pencil") }
                    if result.hasFlour {
                        Button { exportCSV() } label: { Label("Export CSV", systemImage: "tablecells") }
                        Button { exportJSON() } label: { Label("Export JSON", systemImage: "curlybraces") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Formula actions")
            }
        }
        .sheet(isPresented: $editing) {
            FormulaEditView(formula: formula)
        }
        .sheet(isPresented: $showingExport) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
        .onAppear(perform: initializeScaler)
    }

    // MARK: - Headline metrics

    private var headlineCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    MetricTile(label: "Hydration",
                               value: "\(BakersMath.displayPercent(result.hydrationPercent))%",
                               accent: Brand.roleColor(.water))
                    MetricTile(label: "Total flour",
                               value: Units.massWithSuffix(result.totalFlourGrams, unit: settings.massUnit),
                               accent: Brand.roleColor(.flour))
                }
                Divider().overlay(Brand.glassStroke.opacity(0.5))
                HStack(spacing: 16) {
                    MetricTile(label: "Levain",
                               value: "\(BakersMath.displayPercent(result.levainPercent))%",
                               accent: Brand.roleColor(.levain))
                    MetricTile(label: "Salt",
                               value: "\(BakersMath.displayPercent(result.saltPercent))%",
                               accent: Brand.roleColor(.salt))
                    MetricTile(label: "Dough",
                               value: Units.massWithSuffix(result.totalDoughGrams, unit: settings.massUnit))
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - Live scaler

    private var scalerCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 18) {
                SectionLabel(text: "Scale")

                // Total dough weight.
                scalerRow(title: "Total dough",
                          value: Units.massWithSuffix(totalDough, unit: settings.massUnit),
                          range: 100...5000, step: 25,
                          binding: Binding(get: { totalDough },
                                           set: { newValue in
                              totalDough = newValue
                              syncLoafFromDough()
                          }),
                          accessibilityValue: Units.massWithSuffix(totalDough, unit: settings.massUnit))

                Divider().overlay(Brand.glassStroke.opacity(0.4))

                // Loaf count + grams per loaf.
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Loaves")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Brand.text)
                        Spacer()
                        Stepper(value: Binding(get: { loafCount },
                                               set: { newValue in
                            loafCount = max(1, newValue)
                            totalDough = BakersMath.doughWeight(loafCount: loafCount,
                                                                gramsPerLoaf: gramsPerLoaf)
                        }), in: 1...24) {
                            Text("\(loafCount)")
                                .font(Brand.mono(17, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(Brand.text)
                        }
                        .labelsHidden()
                        .frame(width: 120)
                        .accessibilityValue("\(loafCount) loaves")
                    }
                    Text("\(Units.massWithSuffix(gramsPerLoaf, unit: settings.massUnit)) each")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .monospacedDigit()
                }

                Divider().overlay(Brand.glassStroke.opacity(0.4))

                // Target hydration retargets the water rows live.
                scalerRow(title: "Target hydration",
                          value: "\(BakersMath.displayPercent(hydrationTarget))%",
                          range: 50...100, step: 1,
                          binding: Binding(get: { hydrationTarget },
                                           set: { newValue in
                              hydrationTarget = newValue
                              applyHydration(newValue)
                          }),
                          accessibilityValue: "\(BakersMath.displayPercent(hydrationTarget)) percent")

                Text("Drag hydration to rebalance the water rows; levain water is accounted for automatically.")
                    .font(.caption2)
                    .foregroundStyle(Brand.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func scalerRow(title: String, value: String,
                           range: ClosedRange<Double>, step: Double,
                           binding: Binding<Double>, accessibilityValue: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                Spacer()
                Text(value)
                    .font(Brand.mono(17, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Brand.text)
            }
            Slider(value: binding, in: range, step: step)
                .tint(Brand.text)
                .accessibilityLabel(title)
                .accessibilityValue(accessibilityValue)
        }
    }

    // MARK: - Ingredient grams table

    private var ingredientsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "Recipe at this scale")
                ForEach(result.rows) { row in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Brand.roleColor(row.role))
                            .frame(width: 9, height: 9)
                            .accessibilityHidden(true)
                        Text(row.name)
                            .font(.subheadline)
                            .foregroundStyle(Brand.text)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text("\(BakersMath.displayPercent(row.percent))%")
                            .font(Brand.mono(13))
                            .foregroundStyle(Brand.text3)
                            .monospacedDigit()
                            .frame(width: 56, alignment: .trailing)
                        Text(Units.massWithSuffix(row.grams, unit: settings.massUnit))
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text)
                            .monospacedDigit()
                            .frame(width: 76, alignment: .trailing)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(row.name)
                    .accessibilityValue("\(BakersMath.displayPercent(row.percent)) percent, \(Units.massWithSuffix(row.grams, unit: settings.massUnit))")
                    if row.id != result.rows.last?.id {
                        Divider().overlay(Brand.glassStroke.opacity(0.3))
                    }
                }
            }
        }
    }

    // MARK: - Guidance + links

    private var noFlourGuidance: some View {
        GlassCard {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Brand.roleColor(.flour))
                    .accessibilityHidden(true)
                Text("This formula needs flour")
                    .font(.headline)
                    .foregroundStyle(Brand.text)
                Text("Baker's percentages are measured against total flour. Add at least one flour ingredient to compute hydration and weights.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                InkButton(title: "Edit formula", systemImage: "pencil") { editing = true }
            }
        }
    }

    private var bakesLink: some View {
        let bakes = formula.bakes.sorted { $0.date > $1.date }
        return GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Bakes of this formula")
                if bakes.isEmpty {
                    Text("No bakes logged yet. Start one from the Bakes tab.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    ForEach(bakes.prefix(4)) { bake in
                        NavigationLink(value: bake) {
                            HStack {
                                Image(systemName: bake.isComplete ? "checkmark.circle.fill" : "clock")
                                    .foregroundStyle(bake.isComplete ? Brand.live : Brand.text3)
                                    .accessibilityHidden(true)
                                Text(bake.title)
                                    .font(.subheadline)
                                    .foregroundStyle(Brand.text)
                                Spacer()
                                Text(bake.date, format: .dateTime.month().day())
                                    .font(.caption)
                                    .foregroundStyle(Brand.text3)
                                    .monospacedDigit()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationDestination(for: Bake.self) { bake in
            BakeDetailView(bake: bake)
        }
    }

    // MARK: - Scaler logic

    private func initializeScaler() {
        guard !initialized else { return }
        initialized = true
        totalDough = settings.defaultDoughGrams
        let solved = BakersMath.solve(rows: rows, target: .totalDough(grams: totalDough))
        hydrationTarget = solved.hasFlour ? solved.hydrationPercent.rounded() : 75
        loafCount = max(1, BakersMath.loafCount(totalDough: totalDough, gramsPerLoaf: 900))
    }

    private func syncLoafFromDough() {
        // Keep loaf size stable by recomputing count from the current per-loaf size.
        loafCount = max(1, BakersMath.loafCount(totalDough: totalDough, gramsPerLoaf: max(1, gramsPerLoaf)))
    }

    /// Persist the retargeted water percentages so the change is durable and live.
    private func applyHydration(_ target: Double) {
        let updated = BakersMath.retargetHydration(rows: rows, to: target, totalDough: totalDough)
        for newRow in updated where newRow.role == .water {
            if let ing = formula.ingredients.first(where: { $0.id == newRow.id }) {
                ing.percent = newRow.percent
            }
        }
        Haptics.impact(enabled: settings.hapticsEnabled, style: .soft)
    }

    // MARK: - Export

    private func exportCSV() {
        let text = Exporter.formulaCSV(formula, result: result, massUnit: settings.massUnit)
        writeAndShare(text, ext: "csv")
    }

    private func exportJSON() {
        let text = Exporter.formulaJSON(formula, result: result, massUnit: settings.massUnit)
        writeAndShare(text, ext: "json")
    }

    private func writeAndShare(_ text: String, ext: String) {
        let safeName = formula.name.replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let base = safeName.isEmpty ? "formula" : safeName
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(base)
            .appendingPathExtension(ext)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            showingExport = true
            Haptics.success(enabled: settings.hapticsEnabled)
        } catch {
            // Sharing is a convenience; if the temp write fails we simply don't present.
            exportURL = nil
        }
    }
}

#Preview {
    let container = PreviewSupport.container()
    return NavigationStack {
        if let formula = PreviewSupport.sampleFormula(in: container) {
            FormulaDetailView(formula: formula)
        } else {
            Text("No sample formula")
        }
    }
    .environment(SettingsStore())
    .modelContainer(container)
}
