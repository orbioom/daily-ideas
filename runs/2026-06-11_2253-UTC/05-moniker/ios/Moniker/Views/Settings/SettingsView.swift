import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @AppStorage("partnerAName") private var partnerAName = ""
    @AppStorage("partnerBName") private var partnerBName = ""
    @AppStorage("babyLastName") private var babyLastName = ""
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("appearance") private var appearance = "system"
    @Query private var verdicts: [Verdict]

    @State private var confirmReset = false
    @State private var sampleLoaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Who's choosing") {
                    TextField("Partner 1 name", text: $partnerAName)
                        .textInputAutocapitalization(.words)
                    TextField("Partner 2 name", text: $partnerBName)
                        .textInputAutocapitalization(.words)
                    TextField("Baby's last name (optional)", text: $babyLastName)
                        .textInputAutocapitalization(.words)
                }
                Section("Experience") {
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                    Picker("Appearance", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }
                Section("Data") {
                    LabeledContent("Verdicts recorded", value: "\(verdicts.count)")
                    LabeledContent("Matches", value: "\(MatchEngine.matches(verdicts: verdicts).count)")
                    Button("Load sample swipes") { loadSample() }
                        .disabled(sampleLoaded)
                    Button("Reset all swipes", role: .destructive) { confirmReset = true }
                        .disabled(verdicts.isEmpty)
                }
                Section("About") {
                    LabeledContent("Names in catalog", value: "\(NameCatalog.all.count)")
                    LabeledContent("Version", value: "1.0")
                    Text("Moniker is fully on-device. Your name swipes and matches never leave this iPhone — no account, no ads, no selling your nursery plans.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background(scheme))
            .navigationTitle("Settings")
            .confirmationDialog("Reset all swipes for both partners?",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset everything", role: .destructive) {
                    for v in verdicts { context.delete(v) }
                    sampleLoaded = false
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    /// Seeds believable swipes so Matches/Insights have content immediately.
    private func loadSample() {
        if partnerAName.isEmpty { partnerAName = "Sam" }
        if partnerBName.isEmpty { partnerBName = "Alex" }
        let pool = NameCatalog.all
        var rng = SeededRNG(seed: 20260611)
        // Partner A judges ~45 names, Partner B ~40, with deliberate overlap.
        let shuffledA = pool.shuffled(using: &rng).prefix(45)
        let shuffledB = pool.shuffled(using: &rng).prefix(40)
        let calendar = Calendar.current
        var dayOffset = 0
        for card in shuffledA {
            let decision = weightedDecision(&rng)
            let date = calendar.date(byAdding: .hour, value: -dayOffset, to: Date()) ?? Date()
            context.insert(Verdict(nameID: card.id, partner: .a, decision: decision, date: date))
            dayOffset += 1
        }
        for card in shuffledB {
            let decision = weightedDecision(&rng)
            let date = calendar.date(byAdding: .hour, value: -dayOffset, to: Date()) ?? Date()
            context.insert(Verdict(nameID: card.id, partner: .b, decision: decision, date: date))
            dayOffset += 1
        }
        sampleLoaded = true
        Haptics.success()
    }

    private func weightedDecision(_ rng: inout SeededRNG) -> Decision {
        let r = Double(rng.next() % 100)
        if r < 18 { return .superlike }
        if r < 58 { return .like }
        return .pass
    }
}

/// Small deterministic RNG so sample data is reproducible.
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var x = state
        x ^= x >> 33
        x = x &* 0xFF51AFD7ED558CCD
        x ^= x >> 33
        return x
    }
}
