import SwiftUI
import SwiftData

/// Setup for a developing run: choose a saved recipe (or enter ad-hoc film /
/// developer / base time), set the chemistry temperature, push/pull and EI, and
/// see the four computed phase durations live. "Start" hands the plan to the
/// shared TimerEngine and the active timer takes over.
struct DevelopSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var timer: TimerEngine
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @AppStorage("latent.tempUnit") private var tempUnitRaw = TempUnit.celsius.rawValue
    @AppStorage("latent.agitationInterval") private var agitationInterval = 60

    /// Optional prefill (from a recipe's "Develop now").
    let prefill: DevelopPrefill?

    // Selection / ad-hoc entry
    @State private var selectedRecipeID: UUID?
    @State private var adHoc = false
    @State private var filmStock = ""
    @State private var developer = ""
    @State private var dilution = ""
    @State private var baseMinutes = 8
    @State private var baseSeconds = 0
    @State private var stopSec = 60
    @State private var fixSec = 300
    @State private var washSec = 600

    // Run parameters
    @State private var tempC = 20.0
    @State private var pushPull = 0
    @State private var ei = 400

    @State private var loaded = false

    private var tempUnit: TempUnit { TempUnit(rawValue: tempUnitRaw) ?? .celsius }

    private var selectedRecipe: Recipe? {
        guard let id = selectedRecipeID else { return nil }
        return recipes.first { $0.id == id }
    }

    private var baseTimeSec: Int {
        if let r = selectedRecipe, !adHoc { return r.baseTimeSec }
        return baseMinutes * 60 + baseSeconds
    }

    private var resolvedStop: Int { (selectedRecipe != nil && !adHoc) ? (selectedRecipe?.stopSec ?? stopSec) : stopSec }
    private var resolvedFix: Int  { (selectedRecipe != nil && !adHoc) ? (selectedRecipe?.fixSec ?? fixSec) : fixSec }
    private var resolvedWash: Int { (selectedRecipe != nil && !adHoc) ? (selectedRecipe?.washSec ?? washSec) : washSec }

    /// The live phase plan from current inputs.
    private var phases: [Phase] {
        DevEngine.phases(
            baseTimeSec: baseTimeSec,
            baseTempC: selectedRecipe?.baseTempC ?? 20.0,
            stopSec: resolvedStop,
            fixSec: resolvedFix,
            washSec: resolvedWash,
            tempC: tempC,
            pushPull: pushPull,
            agitationEverySec: agitationInterval
        )
    }

    /// A run can start once we have a valid base time and a source: either a
    /// chosen recipe, or ad-hoc mode (where film/developer default sensibly).
    private var canStart: Bool {
        guard baseTimeSec >= DevEngine.minDevSec, !phases.isEmpty else { return false }
        return adHoc || selectedRecipe != nil
    }

    private var film: String { filmStock.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                sourceCard
                if adHoc { adHocCard }
                parametersCard
                planCard
                startButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 32)
        }
        .onAppear(perform: loadOnce)
    }

    // MARK: - Source selection

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "What are you developing?")

            if recipes.isEmpty && !adHoc {
                Text("No saved recipes yet — enter the details by hand below.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }

            Picker("Mode", selection: $adHoc) {
                Text("Saved recipe").tag(false)
                Text("Ad-hoc").tag(true)
            }
            .pickerStyle(.segmented)
            .onChange(of: adHoc) { _, _ in Haptics.selection() }

            if !adHoc {
                if recipes.isEmpty {
                    Text("Switch to Ad-hoc to develop without a saved recipe.")
                        .font(.footnote)
                        .foregroundStyle(Brand.text3)
                } else {
                    Menu {
                        ForEach(recipes) { r in
                            Button {
                                Haptics.selection()
                                applyRecipe(r)
                            } label: {
                                Label(r.name.isEmpty ? r.summary : r.name,
                                      systemImage: selectedRecipeID == r.id ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedRecipe?.name ?? "Choose a recipe")
                                    .font(.headline)
                                    .foregroundStyle(Brand.text)
                                if let r = selectedRecipe {
                                    Text(r.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(Brand.text2)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Brand.text3)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .glassCard()
    }

    private var adHocCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Ad-hoc details")
            TextField("Film stock", text: $filmStock)
                .textInputAutocapitalization(.words)
            TextField("Developer", text: $developer)
                .textInputAutocapitalization(.words)
            TextField("Dilution (e.g. 1+1)", text: $dilution)
                .autocorrectionDisabled()
            HStack {
                Text("Base time @ 20 °C").foregroundStyle(Brand.text2)
                Spacer()
                Text(DevEngine.clock(baseMinutes * 60 + baseSeconds))
                    .font(Brand.mono(16, weight: .semibold))
                    .foregroundStyle(Brand.text)
            }
            Stepper(value: $baseMinutes, in: 0...60) {
                InfoRow(label: "Minutes", value: "\(baseMinutes)", mono: true)
            }
            Stepper(value: $baseSeconds, in: 0...59, step: 5) {
                InfoRow(label: "Seconds", value: String(format: "%02d", baseSeconds), mono: true)
            }
        }
        .glassCard()
    }

    // MARK: - Run parameters

    private var parametersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(text: "Run parameters")

            // Temperature
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Temperature", systemImage: "thermometer.medium")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    Text(Format.tempString(tempC, unit: tempUnit, decimals: 1))
                        .font(Brand.mono(17, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
                Slider(value: $tempC, in: 14...30, step: 0.5) {
                    Text("Temperature")
                } minimumValueLabel: {
                    Text(Format.tempString(14, unit: tempUnit, decimals: 0))
                        .font(Brand.mono(10)).foregroundStyle(Brand.text3)
                } maximumValueLabel: {
                    Text(Format.tempString(30, unit: tempUnit, decimals: 0))
                        .font(Brand.mono(10)).foregroundStyle(Brand.text3)
                }
                .tint(Brand.magic)
                .onChange(of: tempC) { _, _ in Haptics.selection() }
                .accessibilityValue(Format.tempString(tempC, unit: tempUnit, decimals: 1))
            }

            Divider().overlay(Brand.hairline)

            // Push / pull
            Stepper(value: $pushPull, in: -2...3) {
                HStack {
                    Label("Push / pull", systemImage: "plusminus")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    Text(pushPullLabel)
                        .font(Brand.mono(16, weight: .semibold))
                        .foregroundStyle(pushPull == 0 ? Brand.text : Brand.warn)
                }
            }
            .onChange(of: pushPull) { _, _ in Haptics.selection() }

            Divider().overlay(Brand.hairline)

            // EI
            Stepper(value: $ei, in: 12...12800, step: eiStep) {
                HStack {
                    Label("Exposure index", systemImage: "camera.aperture")
                        .font(.subheadline)
                        .foregroundStyle(Brand.text2)
                    Spacer()
                    Text("EI \(ei)")
                        .font(Brand.mono(16, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
            }
            .onChange(of: ei) { _, _ in Haptics.selection() }
        }
        .glassCard()
    }

    private var eiStep: Int {
        if ei < 100 { return 25 }
        if ei < 1000 { return 100 }
        return 400
    }

    private var pushPullLabel: String {
        if pushPull == 0 { return "Box (0)" }
        return pushPull > 0 ? "Push +\(pushPull)" : "Pull −\(abs(pushPull))"
    }

    // MARK: - Live plan

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionTitle(text: "Computed plan")
                Spacer()
                Text("Total \(DevEngine.totalClock(phases))")
                    .font(Brand.mono(13, weight: .medium))
                    .foregroundStyle(Brand.text2)
            }

            ForEach(phases) { phase in
                HStack(spacing: 12) {
                    Image(systemName: phase.kind.symbol)
                        .font(.subheadline)
                        .foregroundStyle(phase.kind == .develop ? Brand.magic : Brand.text2)
                        .frame(width: 22)
                        .accessibilityHidden(true)
                    Text(phase.kind.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    Spacer()
                    Text(DevEngine.clock(phase.seconds))
                        .font(Brand.mono(16, weight: .semibold))
                        .foregroundStyle(Brand.text)
                }
                .padding(.vertical, 3)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(phase.kind.title): \(DevEngine.clock(phase.seconds))")
                if phase.id != phases.last?.id {
                    Divider().overlay(Brand.hairline)
                }
            }

            if pushPull != 0 || tempC != 20.0 {
                Text(adjustmentNote)
                    .font(.footnote)
                    .foregroundStyle(Brand.text2)
                    .padding(.top, 2)
            }
        }
        .glassCard()
    }

    private var adjustmentNote: String {
        let base = DevEngine.clock(baseTimeSec)
        let dev = phases.first(where: { $0.kind == .develop })?.seconds ?? baseTimeSec
        return "Develop adjusted from \(base) at 20 °C to \(DevEngine.clock(dev)) for your temperature and push/pull."
    }

    // MARK: - Start

    private var startButton: some View {
        Button {
            start()
        } label: {
            Label("Start developing", systemImage: "play.fill")
        }
        .buttonStyle(InkButtonStyle())
        .disabled(!canStart)
        .padding(.top, 4)
    }

    private func start() {
        guard !phases.isEmpty else { Haptics.warning(); return }
        let name: String
        let fStock: String
        let dev: String
        let dil: String
        if let r = selectedRecipe, !adHoc {
            name = r.name
            fStock = r.filmStock
            dev = r.developer
            dil = r.dilution
        } else {
            fStock = film.isEmpty ? "Film" : film
            dev = developer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Developer" : developer
            dil = dilution.trimmingCharacters(in: .whitespacesAndNewlines)
            name = "\(fStock) in \(dev)\(dil.isEmpty ? "" : " \(dil)")"
        }
        let pending = PendingRun(
            recipeName: name,
            filmStock: fStock,
            developer: dev,
            dilution: dil,
            ei: ei,
            tempC: tempC,
            pushPull: pushPull,
            recipeID: (adHoc ? nil : selectedRecipe?.id)
        )
        timer.start(phases: phases, setupFrom: pending)
        // If we were pushed in from a recipe's "Develop now", pop back; the run
        // now lives in the shared engine and shows on the Develop tab. As the
        // Develop-tab root this is a harmless no-op.
        if prefill != nil { dismiss() }
    }

    // MARK: - Loading

    private func loadOnce() {
        guard !loaded else { return }
        loaded = true
        if let pre = prefill {
            adHoc = false
            applyRecipe(pre.recipe)
        } else if let first = recipes.first {
            applyRecipe(first)
        } else {
            adHoc = true
        }
    }

    private func applyRecipe(_ r: Recipe) {
        selectedRecipeID = r.id
        ei = r.boxISO
        // Mirror into ad-hoc fields so toggling keeps context.
        filmStock = r.filmStock
        developer = r.developer
        dilution = r.dilution
        baseMinutes = r.baseTimeSec / 60
        baseSeconds = r.baseTimeSec % 60
        stopSec = r.stopSec
        fixSec = r.fixSec
        washSec = r.washSec
    }
}
