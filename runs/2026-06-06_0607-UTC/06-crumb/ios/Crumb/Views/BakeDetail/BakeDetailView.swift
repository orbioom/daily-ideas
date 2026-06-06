import SwiftUI
import SwiftData

/// The bake detail: a computed step timeline (clock times derived from the anchor and
/// direction), editable steps, and the results panel (rating, temps, notes).
struct BakeDetailView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(\.modelContext) private var context
    @Bindable var bake: Bake

    @State private var editingPlan = false
    @State private var editingStep: BakeStep?
    @State private var addingStep = false
    @State private var showingExport = false
    @State private var exportURL: URL?

    /// Next free order index for an appended step (one past the current maximum).
    private var nextStepOrder: Int {
        (bake.steps.map(\.order).max() ?? -1) + 1
    }

    private var scheduled: [BakersMath.ScheduledStep] {
        let planned = bake.orderedSteps.map {
            BakersMath.PlannedStep(id: $0.id, order: $0.order, label: $0.label,
                                   kind: $0.kind, detail: $0.detail,
                                   plannedMinutes: $0.plannedMinutes)
        }
        return BakersMath.schedule(steps: planned, anchor: bake.anchorTime,
                                   fromFinish: bake.schedulesFromFinish)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                timelineCard
                resultsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Brand.pageBackground)
        .navigationTitle(bake.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { editingPlan = true } label: { Label("Edit plan", systemImage: "pencil") }
                    Button { addingStep = true } label: { Label("Add step", systemImage: "plus") }
                    Button { exportCSV() } label: { Label("Export CSV", systemImage: "tablecells") }
                    Button { exportJSON() } label: { Label("Export JSON", systemImage: "curlybraces") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Bake actions")
            }
        }
        .sheet(isPresented: $editingPlan) {
            BakeEditView(bake: bake)
        }
        .sheet(item: $editingStep) { step in
            StepEditView(step: step)
        }
        .sheet(isPresented: $addingStep) {
            StepEditView(step: nil, bake: bake, nextOrder: nextStepOrder)
        }
        .sheet(isPresented: $showingExport) {
            if let exportURL { ShareSheet(items: [exportURL]) }
        }
    }

    // MARK: - Summary

    private var summaryCard: some View {
        GlassCard {
            VStack(spacing: 14) {
                HStack(spacing: 16) {
                    MetricTile(label: "Formula", value: bake.formula?.name ?? "—")
                    MetricTile(label: "Dough",
                               value: Units.massWithSuffix(bake.targetDoughGrams, unit: settings.massUnit))
                }
                Divider().overlay(Brand.glassStroke.opacity(0.5))
                HStack(spacing: 16) {
                    MetricTile(label: "Loaves", value: "\(bake.loafCount)")
                    MetricTile(label: "Per loaf",
                               value: Units.massWithSuffix(
                                BakersMath.gramsPerLoaf(totalDough: bake.targetDoughGrams,
                                                        loafCount: bake.loafCount),
                                unit: settings.massUnit))
                    MetricTile(label: "Oven",
                               value: Units.temperature(bake.ovenTempC, unit: settings.temperatureUnit),
                               accent: Brand.roleColor(.other))
                }
                HStack {
                    Image(systemName: bake.schedulesFromFinish ? "backward.end" : "forward.end")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .accessibilityHidden(true)
                    Text(bake.schedulesFromFinish
                         ? "Finishing by \(timeString(bake.anchorTime))"
                         : "Starting at \(timeString(bake.anchorTime))")
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                        .monospacedDigit()
                    Spacer()
                    Text(BakersMath.durationString(minutes: bake.totalPlannedMinutes))
                        .font(Brand.mono(13, weight: .medium))
                        .foregroundStyle(Brand.text3)
                }
            }
        }
    }

    // MARK: - Timeline

    private var timelineCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionLabel(text: "Timeline")
                    Spacer()
                    if let first = scheduled.first, let last = scheduled.last {
                        Text("\(timeString(first.start)) – \(timeString(last.end))")
                            .font(Brand.mono(12))
                            .foregroundStyle(Brand.text3)
                            .monospacedDigit()
                    }
                }

                if scheduled.isEmpty {
                    Text("No steps yet. Add one to build the timeline.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text3)
                } else {
                    ForEach(Array(scheduled.enumerated()), id: \.element.id) { index, step in
                        timelineRow(step, isLast: index == scheduled.count - 1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if let model = bake.steps.first(where: { $0.id == step.id }) {
                                    editingStep = model
                                }
                            }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func timelineRow(_ step: BakersMath.ScheduledStep, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: step.kind.symbol)
                    .font(.system(size: 14))
                    .foregroundStyle(Brand.text)
                    .frame(width: 30, height: 30)
                    .background(Brand.glassStroke.opacity(0.25), in: Circle())
                    .accessibilityHidden(true)
                if !isLast {
                    Rectangle()
                        .fill(Brand.glassStroke.opacity(0.5))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(step.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Text(BakersMath.durationString(minutes: step.plannedMinutes))
                        .font(Brand.mono(12))
                        .foregroundStyle(Brand.text3)
                        .monospacedDigit()
                }
                Text("\(timeString(step.start)) → \(timeString(step.end))")
                    .font(Brand.mono(13))
                    .foregroundStyle(Brand.text2)
                    .monospacedDigit()
                if !step.detail.isEmpty {
                    Text(step.detail)
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.bottom, isLast ? 0 : 14)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(step.label)
        .accessibilityValue("\(timeString(step.start)) to \(timeString(step.end)), \(BakersMath.durationString(minutes: step.plannedMinutes))")
        .accessibilityHint("Double tap to edit this step")
    }

    // MARK: - Results

    private var resultsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                SectionLabel(text: "Result")

                HStack {
                    Text("Crumb rating")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text)
                    Spacer()
                    StarRating(rating: $bake.crumbRating)
                }

                Toggle("Marked as baked", isOn: $bake.isComplete)
                    .font(.subheadline)
                    .tint(Brand.live)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Oven temperature")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text)
                        Spacer()
                        Text(Units.temperature(bake.ovenTempC, unit: settings.temperatureUnit))
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(Brand.text)
                            .monospacedDigit()
                    }
                    Slider(value: $bake.ovenTempC, in: 150...300, step: 1)
                        .tint(Brand.roleColor(.other))
                        .accessibilityLabel("Oven temperature")
                        .accessibilityValue(Units.temperature(bake.ovenTempC, unit: settings.temperatureUnit))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Final dough temperature")
                            .font(.subheadline)
                            .foregroundStyle(Brand.text)
                        Spacer()
                        Text(bake.doughTempC.isFinite
                             ? Units.temperature(bake.doughTempC, unit: settings.temperatureUnit)
                             : "Not set")
                            .font(Brand.mono(15, weight: .semibold))
                            .foregroundStyle(bake.doughTempC.isFinite ? Brand.text : Brand.text3)
                            .monospacedDigit()
                    }
                    Slider(value: doughTempBinding, in: 18...32, step: 0.5)
                        .tint(Brand.roleColor(.water))
                        .accessibilityLabel("Final dough temperature")
                        .accessibilityValue(bake.doughTempC.isFinite
                                            ? Units.temperature(bake.doughTempC, unit: settings.temperatureUnit)
                                            : "not set")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text)
                    TextField("How did it turn out?", text: $bake.notes, axis: .vertical)
                        .lineLimit(2...6)
                        .padding(10)
                        .background(Brand.glassStroke.opacity(0.2),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    /// Slider binding that materializes a sensible default when the dough temp is unset.
    private var doughTempBinding: Binding<Double> {
        Binding(
            get: { bake.doughTempC.isFinite ? bake.doughTempC : 25 },
            set: { bake.doughTempC = $0 }
        )
    }

    // MARK: - Helpers

    private func timeString(_ date: Date) -> String {
        date.formatted(date: .omitted, time: .shortened)
    }

    private func exportCSV() {
        let text = Exporter.bakeCSV(bake, scheduled: scheduled,
                                    tempUnit: settings.temperatureUnit, massUnit: settings.massUnit)
        writeAndShare(text, ext: "csv")
    }

    private func exportJSON() {
        let text = Exporter.bakeJSON(bake, scheduled: scheduled)
        writeAndShare(text, ext: "json")
    }

    private func writeAndShare(_ text: String, ext: String) {
        let safeName = bake.title.replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let base = safeName.isEmpty ? "bake" : safeName
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(base)
            .appendingPathExtension(ext)
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            showingExport = true
            Haptics.success(enabled: settings.hapticsEnabled)
        } catch {
            exportURL = nil
        }
    }
}

#Preview {
    let container = PreviewSupport.container()
    return NavigationStack {
        if let bake = PreviewSupport.sampleBake(in: container) {
            BakeDetailView(bake: bake)
        } else {
            Text("No sample bake")
        }
    }
    .environment(SettingsStore())
    .modelContainer(container)
}
