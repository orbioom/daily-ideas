import SwiftUI
import SwiftData

struct CalculateView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("useMetric") private var useMetric = true
    @AppStorage("defaultStartState") private var defaultStartRaw = StartState.fridge.rawValue
    @AppStorage("defaultLogReductions") private var defaultLogReductions = 6.5

    @State private var presetIndex: Int? = 0
    @State private var foodName = "Beef steak"
    @State private var category = "Beef"
    @State private var levelIndex = 1
    @State private var bathC = 54.5
    @State private var thickness = 25.0
    @State private var shape: FoodShape = .slab
    @State private var startState: StartState = .fridge
    @State private var logReductions = 6.5
    @State private var startedFlash = false
    @State private var loaded = false

    private var presets: [FoodPreset] { DonenessGuide.presets }
    private var currentPreset: FoodPreset? { presetIndex.flatMap { presets.indices.contains($0) ? presets[$0] : nil } }

    private var plan: CookPlan {
        PlateauMath.plan(thicknessMM: thickness, shape: shape, bathC: bathC,
                         startC: startState.celsius, logReductions: logReductions)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        foodCard
                        donenessCard
                        cutCard
                        safetyCard
                        resultCard
                        startButton
                    }
                    .padding(.horizontal, 18).padding(.vertical, 14)
                }
            }
            .navigationTitle("Calculate")
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        startState = StartState(rawValue: defaultStartRaw) ?? .fridge
        logReductions = defaultLogReductions
    }

    private var foodCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Food")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(presets.enumerated()), id: \.offset) { i, p in
                        chip(p.name, selected: presetIndex == i) { applyPreset(i) }
                    }
                    chip("Custom", selected: presetIndex == nil) {
                        presetIndex = nil; Haptics.selection()
                    }
                }
            }
            if presetIndex == nil {
                TextField("Food name", text: $foodName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 4)
            }
        }
        .glassCard()
    }

    private var donenessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Temperature")
            if let preset = currentPreset {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(preset.levels.enumerated()), id: \.offset) { i, lvl in
                            Button {
                                Haptics.selection(); levelIndex = i; bathC = lvl.celsius
                            } label: {
                                VStack(spacing: 2) {
                                    Text(lvl.name).font(Brand.mono(13, weight: .medium))
                                    Text(TempFmt.tempShort(lvl.celsius, metric: useMetric))
                                        .font(Brand.mono(11))
                                }
                                .foregroundStyle(levelIndex == i ? .white : Brand.text)
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(levelIndex == i ? AnyShapeStyle(Brand.inkGradient)
                                                            : AnyShapeStyle(.ultraThinMaterial), in: Capsule())
                            }
                            .accessibilityLabel("\(lvl.name), \(TempFmt.temp(lvl.celsius, metric: useMetric))")
                        }
                    }
                }
            }
            HStack {
                Text("Bath").font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
                Stepper(TempFmt.temp(bathC, metric: useMetric), value: $bathC, in: 40...90, step: 0.5)
                    .labelsHidden()
                Text(TempFmt.temp(bathC, metric: useMetric))
                    .font(Brand.mono(16, weight: .semibold)).foregroundStyle(Brand.text)
                    .frame(width: 76, alignment: .trailing)
            }
        }
        .glassCard()
    }

    private var cutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "The cut")
            HStack {
                Text("Thickness").font(.subheadline).foregroundStyle(Brand.text2)
                Spacer()
                Stepper("\(Int(thickness)) mm", value: $thickness, in: 5...120, step: 1)
            }
            Picker("Shape", selection: $shape) {
                ForEach(FoodShape.allCases) { s in Text(s.short).tag(s) }
            }
            .pickerStyle(.segmented)
            Picker("Starting", selection: $startState) {
                ForEach(StartState.allCases) { s in Text(s.label).tag(s) }
            }
        }
        .glassCard()
    }

    private var safetyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Pasteurization target")
            Picker("Log reductions", selection: $logReductions) {
                Text("None").tag(0.0)
                Text("6.5-log").tag(6.5)
                Text("7-log").tag(7.0)
                Text("8-log").tag(8.0)
            }
            .pickerStyle(.segmented)
            Text("Higher = safer and longer. Use 0 for cook-and-serve cuts you sear and eat immediately.")
                .font(.caption).foregroundStyle(Brand.text3)
        }
        .glassCard()
    }

    private var resultCard: some View {
        let p = plan
        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                StatTile(value: TempFmt.duration(p.comeUpMinutes), label: "Come-up", accent: Brand.info)
                StatTile(value: p.pasteurizes ? TempFmt.duration(p.pasteurizeMinutes) : "—",
                         label: "Hold", accent: Brand.live)
            }
            VStack(spacing: 4) {
                Text(TempFmt.duration(p.totalMinutes))
                    .font(Brand.mono(34, weight: .bold)).foregroundStyle(Brand.text)
                    .contentTransition(.numericText())
                Text("minimum total time").font(.caption).foregroundStyle(Brand.text3)
            }
            .frame(maxWidth: .infinity)
            HStack(spacing: 10) {
                Image(systemName: p.pasteurizes ? "checkmark.shield" : "info.circle")
                    .foregroundStyle(p.pasteurizes ? Brand.live : Brand.warn).accessibilityHidden(true)
                Text(p.note).font(.caption).foregroundStyle(Brand.text2)
                Spacer()
            }
        }
        .glassCard(padding: 18)
        .accessibilityElement(children: .contain)
    }

    private var startButton: some View {
        VStack(spacing: 10) {
            Button {
                startCook()
            } label: {
                Label(startedFlash ? "Timer started" : "Start cook",
                      systemImage: startedFlash ? "checkmark.circle.fill" : "timer")
            }
            .buttonStyle(InkButtonStyle())
            if startedFlash {
                Text("Counting down in the Timer tab.")
                    .font(.caption).foregroundStyle(Brand.live).transition(.opacity)
            }
        }
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(Brand.mono(13, weight: .medium))
                .foregroundStyle(selected ? .white : Brand.text)
                .padding(.horizontal, 14).padding(.vertical, 9)
                .background(selected ? AnyShapeStyle(Brand.inkGradient)
                                     : AnyShapeStyle(.ultraThinMaterial), in: Capsule())
        }
        .accessibilityLabel(label)
    }

    private func applyPreset(_ i: Int) {
        Haptics.selection()
        presetIndex = i
        let p = presets[i]
        foodName = p.name; category = p.category; shape = p.shape; thickness = p.defaultThicknessMM
        levelIndex = min(levelIndex, p.levels.count - 1)
        if p.levels.indices.contains(levelIndex) { bathC = p.levels[levelIndex].celsius }
        else if let first = p.levels.first { levelIndex = 0; bathC = first.celsius }
    }

    private func startCook() {
        let p = plan
        let cook = Cook(foodName: foodName, category: category, shape: shape, thicknessMM: thickness,
                        bathC: bathC, startState: startState, logReductions: logReductions,
                        comeUpMinutes: p.comeUpMinutes, pasteurizeMinutes: p.pasteurizeMinutes,
                        totalMinutes: p.totalMinutes, startedAt: .now, state: .cooking)
        context.insert(cook)
        try? context.save()
        Haptics.success()
        withAnimation(Brand.ease(0.3)) { startedFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(Brand.ease(0.3)) { startedFlash = false }
        }
    }
}
