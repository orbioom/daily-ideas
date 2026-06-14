import SwiftUI
import SwiftData

/// Practice Setup: choose clef, range, accidentals, and length, then start a drill.
struct PracticeHomeView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Query private var sessions: [DrillSession]

    @State private var clef: Clef = .treble
    @State private var range: NoteRange = .staffOnly
    @State private var accidentals = false
    @State private var lengthChoice: LengthChoice = .twenty
    @State private var paywall: PaywallReason?
    @State private var activeConfig: DrillConfig?
    @State private var didInit = false

    enum LengthChoice: Int, CaseIterable, Identifiable {
        case ten = 10, twenty = 20, fifty = 50, timed = -1
        var id: Int { rawValue }
        var label: String { self == .timed ? "Timed 60s" : "\(rawValue)" }
        var isTimed: Bool { self == .timed }
        var requiresPro: Bool { self == .timed || self == .fifty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    clefCard
                    rangeCard
                    accidentalsCard
                    lengthCard
                    bestForConfigCard
                    startButton
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Practice")
            .sheet(item: $paywall) { PaywallView(reason: $0) }
            .fullScreenCover(item: $activeConfig) { cfg in
                DrillPlayerView(config: cfg)
            }
            .onAppear { initializeDefaults() }
        }
    }

    private func initializeDefaults() {
        guard !didInit else { return }
        didInit = true
        clef = Pro.clefAllowed(settings.defaultClef, isPro: isPro) ? settings.defaultClef : .treble
        accidentals = false
    }

    // MARK: Clef

    private var clefCard: some View {
        CardSection("Clef") {
            VStack(spacing: 10) {
                ForEach(Clef.allCases) { c in
                    clefRow(c)
                }
            }
        }
    }

    private func clefRow(_ c: Clef) -> some View {
        let locked = c.requiresPro && !isPro
        return Button {
            if locked {
                paywall = .clefs
            } else {
                clef = c
                Haptics.tap(settings.hapticsEnabled)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: clef == c ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(clef == c ? Theme.accent : Theme.inkFaint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(c.displayName)
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(c.subtitle)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.inkFaint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(c.displayName) clef\(locked ? ", locked, requires Pro" : "")")
        .accessibilityAddTraits(clef == c ? .isSelected : [])
    }

    // MARK: Range

    private var rangeCard: some View {
        CardSection("Note range") {
            VStack(spacing: 10) {
                ForEach(NoteRange.allCases) { r in
                    let locked = r.requiresPro && !isPro
                    Button {
                        if locked { paywall = .fullRange }
                        else { range = r; Haptics.tap(settings.hapticsEnabled) }
                    } label: {
                        HStack {
                            Image(systemName: range == r ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(range == r ? Theme.accent : Theme.inkFaint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.label).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                                Text(r.subtitle).font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            if locked {
                                Image(systemName: "lock.fill").font(.system(size: 13)).foregroundStyle(Theme.inkFaint)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(r.label) range\(locked ? ", locked, requires Pro" : "")")
                    .accessibilityAddTraits(range == r ? .isSelected : [])
                }
            }
        }
    }

    // MARK: Accidentals

    private var accidentalsCard: some View {
        CardSection("Accidentals") {
            Toggle(isOn: Binding(
                get: { accidentals },
                set: { newVal in
                    if newVal && !isPro { paywall = .accidentals }
                    else { accidentals = newVal }
                })) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Include sharps & flats")
                            .font(Theme.rounded(16, .semibold))
                            .foregroundStyle(Theme.ink)
                        if !isPro {
                            Image(systemName: "lock.fill").font(.system(size: 11)).foregroundStyle(Theme.inkFaint)
                        }
                    }
                    Text("Add the black keys to the pool")
                        .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                }
            }
            .tint(Theme.accent)
        }
    }

    // MARK: Length

    private var lengthCard: some View {
        CardSection("Length") {
            let columns = [GridItem(.adaptive(minimum: 88), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(LengthChoice.allCases) { choice in
                    let locked = choice.requiresPro && !isPro
                    Button {
                        if locked {
                            paywall = choice.isTimed ? .timed : .clefs
                        } else {
                            lengthChoice = choice
                            Haptics.tap(settings.hapticsEnabled)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(choice.label).font(Theme.rounded(15, .semibold))
                            if locked { Image(systemName: "lock.fill").font(.system(size: 10)) }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(lengthChoice == choice ? Theme.accent : Theme.surfaceAlt)
                        )
                        .foregroundStyle(lengthChoice == choice ? .white : Theme.ink)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Length \(choice.label)\(locked ? ", locked" : "")")
                    .accessibilityAddTraits(lengthChoice == choice ? .isSelected : [])
                }
            }
        }
    }

    // MARK: Best for config

    private var bestForConfigCard: some View {
        let best = bestAccuracy()
        return CardSection("Your best") {
            if let best {
                HStack(spacing: 12) {
                    Image(systemName: "rosette").font(.system(size: 22)).foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(best.accuracy * 100))% accuracy")
                            .font(Theme.rounded(17, .bold)).foregroundStyle(Theme.ink)
                        Text("Best \(clef.displayName) run · streak \(best.bestStreak)")
                            .font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                    }
                    Spacer()
                }
            } else {
                Text("No \(clef.displayName.lowercased()) drills yet — your best run will show here.")
                    .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
            }
        }
    }

    private func bestAccuracy() -> DrillSession? {
        sessions
            .filter { $0.clefRaw == clef.rawValue && $0.total > 0 }
            .max { $0.accuracy < $1.accuracy }
    }

    // MARK: Start

    private var startButton: some View {
        PrimaryButton(title: "Start drill", systemImage: "play.fill") {
            startDrill()
        }
        .padding(.top, 4)
    }

    private func startDrill() {
        let mode: DrillMode = lengthChoice.isTimed ? .timed : .fixedCount
        let length = lengthChoice.isTimed ? 0 : lengthChoice.rawValue
        var cfg = DrillConfig(clef: clef, range: range, accidentals: accidentals, mode: mode, length: length)
        // Final guards against any state slipping past the Pro gates.
        if cfg.clef.requiresPro && !isPro { cfg.clef = .treble }
        if cfg.range.requiresPro && !isPro { cfg.range = .oneLedger }
        if cfg.accidentals && !isPro { cfg.accidentals = false }
        if cfg.mode == .timed && !isPro { cfg.mode = .fixedCount; cfg.length = 20 }
        if cfg.mode == .fixedCount && !Pro.lengthAllowed(cfg.length, isPro: isPro) { cfg.length = Pro.freeMaxLength }
        Haptics.select(settings.hapticsEnabled)
        activeConfig = cfg
    }
}

extension DrillConfig: Identifiable {
    var id: String {
        "\(clef.rawValue)-\(range.rawValue)-\(accidentals)-\(mode.rawValue)-\(length)"
    }
}
