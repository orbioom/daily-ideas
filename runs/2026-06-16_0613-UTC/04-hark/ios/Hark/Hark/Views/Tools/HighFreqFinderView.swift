import SwiftUI

struct HighFreqFinderView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var engine = AudioEngine()
    @State private var isPlaying = false
    @State private var frequency: Double = 4000
    @State private var ear: Ear = .right
    @State private var highestHeard: Double?
    @State private var audioError: String?

    private let minFreq: Double = 1000
    private let maxFreq: Double = 18000
    /// Fixed, comfortable listening gain for the tools (well below the screening max).
    private let toolGain: Float = 0.18

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                instructions

                Card {
                    VStack(spacing: 16) {
                        Text(Audiometry.label(forFrequency: Int(frequency.rounded())))
                            .font(Theme.rounded(40, .bold))
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.numericText())
                            .accessibilityLabel("Current frequency \(Int(frequency.rounded())) hertz")

                        Slider(value: $frequency, in: minFreq...maxFreq, step: 100) {
                            Text("Frequency")
                        } minimumValueLabel: {
                            Text("1k").font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                        } maximumValueLabel: {
                            Text("18k").font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                        }
                        .tint(Theme.accent)
                        .onChange(of: frequency) { _, newValue in
                            if isPlaying {
                                engine.startContinuous(frequency: newValue, linearGain: toolGain, ear: ear)
                            }
                        }

                        EarPicker(ear: $ear)
                            .onChange(of: ear) { _, newValue in
                                if isPlaying {
                                    engine.startContinuous(frequency: frequency, linearGain: toolGain, ear: newValue)
                                }
                            }

                        Button {
                            togglePlay()
                        } label: {
                            PrimaryButtonLabel(
                                title: isPlaying ? "Stop tone" : "Play tone",
                                systemImage: isPlaying ? "stop.fill" : "play.fill"
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            highestHeard = frequency
                            Haptics.success(enabled: settings.hapticsEnabled)
                        } label: {
                            Text("I can still hear this — mark my limit")
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        .disabled(!isPlaying)
                        .opacity(isPlaying ? 1 : 0.5)
                    }
                }

                if let highestHeard {
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(Theme.good)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Your high-frequency limit")
                                    .font(Theme.rounded(14, .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text("\(Audiometry.label(forFrequency: Int(highestHeard.rounded()))) in your \(ear.rawValue.lowercased()) ear")
                                    .font(Theme.rounded(14))
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                if let audioError {
                    errorCard(audioError)
                }

                Text("High-frequency hearing usually fades first with age and noise. This is a fun gauge, not a diagnosis.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Limit finder")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            engine.teardown()
        }
    }

    private var instructions: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "How to use")
                Text("Start low and raise the pitch slowly. When the tone disappears, you've passed your limit — step back and mark the highest pitch you can still hear.")
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func togglePlay() {
        Haptics.selection(enabled: settings.hapticsEnabled)
        if isPlaying {
            engine.stop()
            isPlaying = false
            return
        }
        do {
            try engine.prepare()
            engine.startContinuous(frequency: frequency, linearGain: toolGain, ear: ear)
            isPlaying = true
            audioError = nil
        } catch {
            audioError = (error as? AudioEngineError)?.errorDescription ?? "Audio is unavailable right now."
            isPlaying = false
        }
    }

    private func errorCard(_ message: String) -> some View {
        Card {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(Theme.warn)
                    .accessibilityHidden(true)
                Text(message)
                    .font(Theme.rounded(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// Segmented right/left ear picker used by the tools.
struct EarPicker: View {
    @Binding var ear: Ear
    var body: some View {
        Picker("Ear", selection: $ear) {
            ForEach(Ear.allCases) { e in
                Text(e.rawValue).tag(e)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Ear")
    }
}
