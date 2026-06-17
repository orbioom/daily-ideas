import SwiftUI
import SwiftData

/// Real, persisted preferences plus account/data actions.
struct SettingsScreen: View {
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.isPro) private var isPro = false
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(PrefKey.beepEnabled) private var beepEnabled = true
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue
    @AppStorage(PrefKey.poolLengthRaw) private var poolLengthRaw = PoolLength.scm25.rawValue
    @AppStorage(PrefKey.defaultRestSeconds) private var defaultRestSeconds = 20
    @AppStorage(PrefKey.defaultStrokeRaw) private var defaultStrokeRaw = Stroke.freestyle.rawValue
    @AppStorage(PrefKey.bodyWeightKg) private var bodyWeightKg = 72.0
    @AppStorage(PrefKey.didSeed) private var didSeed = false

    @State private var paywallReason: PaywallReason?
    @State private var showResetConfirm = false
    @State private var sampleLoaded = false

    private var unit: Binding<DistanceUnit> {
        Binding(get: { DistanceUnit(rawValue: unitsRaw) ?? .meters },
                set: { unitsRaw = $0.rawValue })
    }
    private var pool: Binding<PoolLength> {
        Binding(get: { PoolLength(rawValue: poolLengthRaw) ?? .scm25 },
                set: { poolLengthRaw = $0.rawValue })
    }
    private var stroke: Binding<Stroke> {
        Binding(get: { Stroke.from(defaultStrokeRaw) },
                set: { defaultStrokeRaw = $0.rawValue })
    }

    var body: some View {
        NavigationStack {
            Form {
                proSection
                poolSection
                intervalSection
                profileSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
            .confirmationDialog("Reset all data?",
                                isPresented: $showResetConfirm,
                                titleVisibility: .visible) {
                Button("Erase and reload samples", role: .destructive) { resetData() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes all workouts and logged swims, then reloads the built-in samples.")
            }
        }
    }

    private var proSection: some View {
        Section {
            if isPro {
                HStack {
                    Label("Wake Pro", systemImage: "crown.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("Unlocked")
                        .foregroundStyle(Theme.good)
                        .font(.subheadline.weight(.semibold))
                }
            } else {
                Button {
                    paywallReason = .general
                } label: {
                    Label("Unlock Wake Pro · \(Pro.priceLabel)", systemImage: "crown.fill")
                }
                Button("Restore Purchase") {
                    paywallReason = .general
                }
                .foregroundStyle(Theme.inkSoft)
            }
        } header: {
            Text("Pro")
        } footer: {
            Text(isPro ? "Thanks for supporting Wake." : "Custom workout builder, pace trends, SWOLF, and unlimited saved workouts.")
        }
    }

    private var poolSection: some View {
        Section("Pool & units") {
            Picker("Pool length", selection: pool) {
                ForEach(PoolLength.allCases) { p in
                    Text(p.label).tag(p)
                }
            }
            Picker("Distance units", selection: unit) {
                ForEach(DistanceUnit.allCases) { u in
                    Text(u.label).tag(u)
                }
            }
        }
    }

    private var intervalSection: some View {
        Section {
            Picker("Default stroke", selection: stroke) {
                ForEach(Stroke.allCases) { s in
                    Text(s.label).tag(s)
                }
            }
            Stepper(value: $defaultRestSeconds, in: 0...120, step: 5) {
                Text("Default rest: \(defaultRestSeconds)s")
            }
            Toggle("Interval beep & cue", isOn: $beepEnabled)
            Toggle("Haptics", isOn: $hapticsEnabled)
        } header: {
            Text("Intervals")
        } footer: {
            Text("Cues fire when a rest period is about to end.")
        }
    }

    private var profileSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Body weight: \(Int(bodyWeightKg)) kg")
                    .font(.subheadline)
                Slider(value: $bodyWeightKg, in: 35...160, step: 1)
                    .tint(Theme.accent)
                    .accessibilityValue("\(Int(bodyWeightKg)) kilograms")
            }
        } header: {
            Text("Profile")
        } footer: {
            Text("Used only for rough calorie estimates, on-device.")
        }
    }

    private var dataSection: some View {
        Section("Data") {
            NavigationLink {
                ExportView()
            } label: {
                Label("Export swims", systemImage: "square.and.arrow.up")
            }
            Button {
                loadSample()
            } label: {
                Label(sampleLoaded ? "Samples loaded" : "Load sample data", systemImage: "tray.and.arrow.down")
            }
            .disabled(sampleLoaded)
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("Reset all data", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            NavigationLink {
                AboutView()
            } label: {
                Label("About Wake", systemImage: "info.circle")
            }
        }
    }

    // MARK: - Actions

    private func loadSample() {
        SeedData.seedWorkouts(context: context)
        SeedData.seedSessions(context: context)
        try? context.save()
        sampleLoaded = true
        Haptics.success(hapticsEnabled)
    }

    private func resetData() {
        SeedData.clearAll(context: context)
        var seeded = false
        SeedData.seedIfNeeded(context: context, didSeed: &seeded)
        didSeed = true
        sampleLoaded = false
        Haptics.warning(hapticsEnabled)
    }
}
