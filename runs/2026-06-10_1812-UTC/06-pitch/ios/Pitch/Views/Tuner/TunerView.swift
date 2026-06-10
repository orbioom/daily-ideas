import SwiftUI
import UIKit
import SwiftData
import AVFoundation

struct TunerView: View {
    @EnvironmentObject private var audio: AudioInput
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \CustomTuning.createdAt) private var customTunings: [CustomTuning]

    @AppStorage("selectedTuningId") private var selectedTuningId = "guitar-standard"
    @AppStorage("a4") private var a4 = 440.0
    @AppStorage("useFlats") private var useFlats = false

    @State private var smoothed: Double = 0

    private var currentNotes: [String] {
        if selectedTuningId.hasPrefix("custom-") {
            let id = String(selectedTuningId.dropFirst("custom-".count))
            return customTunings.first { $0.id.uuidString == id }?.noteNames ?? []
        }
        return TuningPreset.all.first { $0.id == selectedTuningId }?.notes ?? []
    }
    private var currentName: String {
        if selectedTuningId.hasPrefix("custom-") {
            let id = String(selectedTuningId.dropFirst("custom-".count))
            return customTunings.first { $0.id.uuidString == id }?.name ?? "Custom"
        }
        if let p = TuningPreset.all.first(where: { $0.id == selectedTuningId }) {
            return "\(p.instrument.rawValue) · \(p.name)"
        }
        return "Chromatic"
    }

    private var resolved: ResolvedNote? {
        guard smoothed > 0 else { return nil }
        return TunerEngine.resolve(frequency: smoothed, a4: a4, useFlats: useFlats)
    }
    private var target: (name: String, frequency: Double, cents: Double)? {
        guard smoothed > 0, !currentNotes.isEmpty else { return nil }
        return TunerEngine.nearestTarget(to: smoothed, in: currentNotes, a4: a4)
    }
    private var displayName: String { target?.name ?? resolved?.displayName ?? "—" }
    private var cents: Double { target?.cents ?? resolved?.cents ?? 0 }
    private var listening: Bool { audio.isRunning && audio.clarity > 0.2 }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                switch audio.permission {
                case .granted: tunerContent
                case .denied: deniedView
                default: permissionView
                }
            }
            .navigationTitle("Tuner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Tuning", selection: $selectedTuningId) {
                            Text("Chromatic").tag("chromatic")
                            ForEach(InstrumentKind.allCases.filter { $0 != .chromatic }) { inst in
                                Section(inst.rawValue) {
                                    ForEach(TuningPreset.presets(for: inst)) { p in
                                        Text(p.name).tag(p.id)
                                    }
                                }
                            }
                            if !customTunings.isEmpty {
                                Section("Custom") {
                                    ForEach(customTunings) { t in
                                        Text(t.name).tag("custom-\(t.id.uuidString)")
                                    }
                                }
                            }
                        }
                    } label: { Image(systemName: "slider.horizontal.3") }
                }
            }
        }
        .onChange(of: audio.frequency) { _, new in
            // Light smoothing for a stable readout.
            smoothed = smoothed == 0 ? new : smoothed * 0.7 + new * 0.3
        }
        .onChange(of: audio.clarity) { _, c in if c < 0.05 { smoothed = 0 } }
        .onAppear { startIfPossible() }
        .onDisappear { audio.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { startIfPossible() } else { audio.stop() }
        }
    }

    private var tunerContent: some View {
        VStack(spacing: 18) {
            Text(currentName)
                .font(Brand.mono(13)).foregroundStyle(Brand.text3)
                .padding(.top, 4)

            // Big note readout.
            VStack(spacing: 2) {
                Text(displayName)
                    .font(.system(size: 84, weight: .bold, design: .rounded))
                    .foregroundStyle(listening ? (abs(cents) <= 5 ? Brand.live : Brand.text) : Brand.text3)
                    .contentTransition(.numericText())
                    .animation(Brand.ease(0.3), value: displayName)
                Text(listening ? String(format: "%.1f Hz", smoothed) : "Listening…")
                    .font(Brand.mono(14)).foregroundStyle(Brand.text2)
            }

            CentsGauge(cents: cents, active: listening)
                .frame(height: 130)
                .padding(.horizontal, 24)

            Text(centsLabel)
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(listening ? (abs(cents) <= 5 ? Brand.live : (cents < 0 ? Brand.info : Brand.warn)) : Brand.text3)

            Spacer()

            if !currentNotes.isEmpty { stringsRow }
        }
        .padding(16)
    }

    private var centsLabel: String {
        guard listening else { return "Play a note" }
        if abs(cents) <= 5 { return "In tune" }
        return cents < 0 ? "♭ \(Int(abs(cents))) cents flat — tune up" : "♯ \(Int(cents)) cents sharp — tune down"
    }

    private var stringsRow: some View {
        HStack(spacing: 8) {
            ForEach(currentNotes, id: \.self) { note in
                let isTarget = target?.name == note && listening
                VStack(spacing: 4) {
                    Text(note)
                        .font(Brand.mono(15, weight: .semibold))
                        .foregroundStyle(isTarget ? .white : Brand.text)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isTarget ? AnyShapeStyle(abs(cents) <= 5 ? Brand.live : Brand.info)
                            : AnyShapeStyle(.ultraThinMaterial), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Brand.glassStroke.opacity(0.4), lineWidth: 1))
            }
        }
        .padding(.bottom, 8)
        .accessibilityHidden(true)
    }

    private var permissionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.fill").font(.system(size: 52, weight: .light)).foregroundStyle(Brand.warn)
            Text("Let Pitch hear your instrument")
                .font(.title2.weight(.semibold)).foregroundStyle(Brand.text)
            Text("The tuner needs microphone access to detect the notes you play. Audio is processed live on your device and never recorded.")
                .font(.subheadline).foregroundStyle(Brand.text2).multilineTextAlignment(.center)
            Button("Enable microphone") {
                Task { _ = await audio.requestPermission(); startIfPossible() }
            }
            .buttonStyle(InkButtonStyle())
        }
        .padding(32)
    }

    private var deniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.slash.fill").font(.system(size: 52, weight: .light)).foregroundStyle(Brand.danger)
            Text("Microphone is off")
                .font(.title2.weight(.semibold)).foregroundStyle(Brand.text)
            Text("Enable microphone access for Pitch in the Settings app to use the tuner.")
                .font(.subheadline).foregroundStyle(Brand.text2).multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .buttonStyle(InkButtonStyle())
        }
        .padding(32)
    }

    private func startIfPossible() {
        audio.refreshPermission()
        if audio.permission == .granted { audio.start() }
    }
}
