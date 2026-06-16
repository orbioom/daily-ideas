import SwiftUI
import SwiftData

struct TinnitusMatcherView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Query(sort: \TinnitusMatch.date, order: .reverse) private var matches: [TinnitusMatch]

    @State private var engine = AudioEngine()
    @State private var isPlaying = false
    @State private var frequency: Double = 6000
    @State private var ear: Ear = .right
    @State private var note = ""
    @State private var audioError: String?
    @State private var showSaved = false

    private let minFreq: Double = 500
    private let maxFreq: Double = 14000
    private let toolGain: Float = 0.16

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "How to use")
                        Text("Play the tone and slide the pitch until it sits right on top of your tinnitus. Save it to track whether your ringing shifts over time.")
                            .font(Theme.rounded(14))
                            .foregroundStyle(Theme.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Card {
                    VStack(spacing: 16) {
                        Text(Audiometry.label(forFrequency: Int(frequency.rounded())))
                            .font(Theme.rounded(40, .bold))
                            .foregroundStyle(Theme.ink)
                            .contentTransition(.numericText())
                            .accessibilityLabel("Current frequency \(Int(frequency.rounded())) hertz")

                        Slider(value: $frequency, in: minFreq...maxFreq, step: 50) {
                            Text("Frequency")
                        } minimumValueLabel: {
                            Text("500").font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
                        } maximumValueLabel: {
                            Text("14k").font(Theme.rounded(12)).foregroundStyle(Theme.inkSoft)
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

                        Button { togglePlay() } label: {
                            PrimaryButtonLabel(
                                title: isPlaying ? "Stop tone" : "Play tone",
                                systemImage: isPlaying ? "stop.fill" : "play.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Note (optional)")
                        TextField("e.g. high whistle, worse at night", text: $note, axis: .vertical)
                            .font(Theme.rounded(15))
                            .lineLimit(1...3)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: Theme.rChip).fill(Theme.surfaceAlt))
                            .accessibilityLabel("Tinnitus note")

                        Button { saveMatch() } label: {
                            PrimaryButtonLabel(title: "Save this match", systemImage: "tray.and.arrow.down")
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let audioError {
                    Card {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle").foregroundStyle(Theme.warn)
                                .accessibilityHidden(true)
                            Text(audioError)
                                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                if !matches.isEmpty {
                    Card {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionLabel(text: "Saved matches")
                            ForEach(matches) { m in
                                savedRow(m)
                                if m.id != matches.last?.id { Divider().background(Theme.hairline) }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Tinnitus matcher")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .top) {
            if showSaved {
                SuccessToast(message: "Match saved")
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onDisappear { engine.teardown() }
    }

    private func savedRow(_ m: TinnitusMatch) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(Audiometry.label(forFrequency: Int(m.frequency.rounded())))
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.ink)
                BandEarTag(ear: m.ear)
                Spacer()
                Text(m.date, format: .dateTime.month().day().year())
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
            }
            if !m.note.isEmpty {
                Text(m.note)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Int(m.frequency.rounded())) hertz, \(m.ear.rawValue) ear, saved \(m.date.formatted(date: .abbreviated, time: .omitted)). \(m.note)")
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

    private func saveMatch() {
        let match = TinnitusMatch(frequency: frequency, ear: ear, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(match)
        do {
            try context.save()
            Haptics.success(enabled: settings.hapticsEnabled)
            note = ""
            withAnimation { showSaved = true }
            Task {
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                withAnimation { showSaved = false }
            }
        } catch {
            audioError = "Couldn't save that match. Please try again."
        }
    }
}

/// Small ear tag used in saved-match rows.
struct BandEarTag: View {
    let ear: Ear
    var body: some View {
        Text(ear.short)
            .font(Theme.rounded(12, .bold))
            .foregroundStyle(ear == .right ? Theme.earRight : Theme.earLeft)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill((ear == .right ? Theme.earRight : Theme.earLeft).opacity(0.16)))
    }
}
