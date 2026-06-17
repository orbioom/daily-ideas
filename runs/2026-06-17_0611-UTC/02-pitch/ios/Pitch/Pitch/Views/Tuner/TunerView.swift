import SwiftUI
import SwiftData

/// Live tuner screen: gauge + big note readout + per-string highlight for the
/// active tuning. Handles permission-denied, listening, and detecting states.
struct TunerView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(TunerEngine.self) private var tuner
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CustomTuning.createdAt) private var customTunings: [CustomTuning]

    @AppStorage("activeTuningID") private var activeTuningID: String = TuningCatalog.defaultID
    @AppStorage("a4Reference") private var a4Reference: Double = NoteMath.defaultA4
    @AppStorage("inTuneToleranceCents") private var tolerance: Double = 5
    @AppStorage("hapticOnBeat") private var hapticsEnabled: Bool = true

    @State private var lastInTuneNote: String?

    private var activeTuning: Tuning {
        if let custom = customTunings.first(where: { "custom-\($0.uuid)" == activeTuningID }) {
            return custom.asTuning
        }
        return TuningCatalog.byID(activeTuningID)
            ?? TuningCatalog.byID(TuningCatalog.defaultID)
            ?? TuningCatalog.all.first
            ?? Tuning(id: "chromatic", name: "Chromatic", instrument: .chromatic, targets: [])
    }

    /// Which target string the detected pitch is closest to (by frequency).
    private var nearestTargetIndex: Int? {
        guard let freq = tuner.frequency, !activeTuning.targets.isEmpty else { return nil }
        var best: (idx: Int, dist: Double)?
        for (i, token) in activeTuning.targets.enumerated() {
            guard let parsed = NoteMath.parseTarget(token),
                  let target = NoteMath.frequency(forName: parsed.name, octave: parsed.octave, a4: a4Reference)
            else { continue }
            // Compare in cents space so distance is perceptually fair.
            let dist = abs(1200 * log2(freq / target))
            if let current = best {
                if dist < current.dist { best = (i, dist) }
            } else {
                best = (i, dist)
            }
        }
        return best?.idx
    }

    private var isInTune: Bool {
        guard let r = tuner.reading else { return false }
        return abs(r.cents) <= tolerance
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PitchTheme.appBackground(scheme).ignoresSafeArea()
                content
            }
            .navigationTitle("Tuner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(activeTuning.name)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                }
            }
        }
        .onAppear {
            tuner.a4Reference = a4Reference
            tuner.refreshPermission()
            tuner.requestPermissionAndStart()
        }
        .onDisappear { tuner.stop() }
        .onChange(of: a4Reference) { _, newValue in tuner.a4Reference = newValue }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                tuner.requestPermissionAndStart()
            } else {
                tuner.stop()
            }
        }
        .onChange(of: isInTune) { _, nowInTune in
            // Sparse haptic only when we newly settle in tune on a note.
            guard let label = tuner.reading?.label else { lastInTuneNote = nil; return }
            if nowInTune, lastInTuneNote != label {
                lastInTuneNote = label
                Haptics.success(hapticsEnabled)
            } else if !nowInTune {
                lastInTuneNote = nil
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tuner.status {
        case .denied:
            permissionDenied
        case .failed(let message):
            InfoStateView(icon: "exclamationmark.triangle.fill",
                          title: "Microphone error",
                          message: message,
                          tint: PitchTheme.offTune,
                          actionTitle: "Try again") { tuner.start() }
        default:
            liveTuner
        }
    }

    private var permissionDenied: some View {
        InfoStateView(icon: "mic.slash.fill",
                      title: "Microphone access needed",
                      message: "Pitch needs the microphone to hear the note you're playing. Enable it in Settings › Pitch › Microphone.",
                      tint: PitchTheme.offTune,
                      actionTitle: "Open Settings") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
    }

    private var liveTuner: some View {
        ScrollView {
            VStack(spacing: 22) {
                noteReadout
                CentsGauge(cents: tuner.reading?.cents,
                           inTune: isInTune,
                           tolerance: tolerance)
                    .padding(.horizontal, 8)

                if tuner.status == .listening || tuner.reading == nil {
                    listeningHint
                }

                if !activeTuning.targets.isEmpty {
                    stringRows
                }
            }
            .padding(20)
        }
    }

    private var noteReadout: some View {
        VStack(spacing: 4) {
            if let r = tuner.reading {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(r.name)
                        .font(PitchTheme.display(76))
                        .foregroundStyle(isInTune ? PitchTheme.inTune : PitchTheme.primaryText(scheme))
                    Text("\(r.octave)")
                        .font(PitchTheme.display(40))
                        .foregroundStyle(PitchTheme.secondaryText(scheme))
                }
                .shadow(color: isInTune ? PitchTheme.inTune.opacity(0.6) : .clear, radius: isInTune ? 14 : 0)

                Text(frequencyText)
                    .font(PitchTheme.mono(16))
                    .foregroundStyle(PitchTheme.secondaryText(scheme))

                if isInTune {
                    Label("In tune", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PitchTheme.inTune)
                        .padding(.top, 2)
                }
            } else {
                Text("—")
                    .font(PitchTheme.display(76))
                    .foregroundStyle(PitchTheme.secondaryText(scheme).opacity(0.5))
                Text("Play a note")
                    .font(PitchTheme.mono(16))
                    .foregroundStyle(PitchTheme.secondaryText(scheme))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Detected note")
        .accessibilityValue(accessibilityReadout)
    }

    private var frequencyText: String {
        guard let f = tuner.frequency else { return "— Hz" }
        return String(format: "%.1f Hz", f)
    }

    private var accessibilityReadout: String {
        guard let r = tuner.reading else { return "No note detected. Play a note." }
        let rounded = Int(r.cents.rounded())
        if abs(rounded) <= Int(tolerance) {
            return "\(r.name)\(r.octave), in tune"
        }
        let direction = rounded > 0 ? "sharp" : "flat"
        return "\(r.name)\(r.octave), \(abs(rounded)) cents \(direction)"
    }

    private var listeningHint: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Listening…")
                .font(.subheadline)
                .foregroundStyle(PitchTheme.secondaryText(scheme))
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Listening for a note")
    }

    private var stringRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            PitchSectionHeader(title: "Strings", systemImage: "guitars")
            VStack(spacing: 8) {
                ForEach(Array(activeTuning.targets.enumerated()), id: \.offset) { index, token in
                    stringRow(index: index, token: token)
                }
            }
        }
    }

    private func stringRow(index: Int, token: String) -> some View {
        let highlighted = nearestTargetIndex == index
        let settled = highlighted && isInTune
        return HStack {
            Text("\(index + 1)")
                .font(PitchTheme.mono(14))
                .foregroundStyle(PitchTheme.secondaryText(scheme))
                .frame(width: 22)
            Text(displayToken(token))
                .font(PitchTheme.display(20))
                .foregroundStyle(settled ? PitchTheme.inTune : PitchTheme.primaryText(scheme))
            Spacer()
            if highlighted {
                Image(systemName: settled ? "checkmark.circle.fill" : "dot.radiowaves.left.and.right")
                    .foregroundStyle(settled ? PitchTheme.inTune : PitchTheme.indigo)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(highlighted ? PitchTheme.indigo.opacity(settled ? 0.18 : 0.12) : PitchTheme.subtleSurface(scheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(settled ? PitchTheme.inTune : (highlighted ? PitchTheme.indigo : .clear),
                              lineWidth: highlighted ? 1.5 : 0)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("String \(index + 1), \(displayToken(token))")
        .accessibilityValue(settled ? "in tune" : (highlighted ? "selected" : ""))
    }

    private func displayToken(_ token: String) -> String {
        guard let parsed = NoteMath.parseTarget(token) else { return token }
        return "\(parsed.name)\(parsed.octave)"
    }
}
