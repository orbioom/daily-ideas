import SwiftUI
import SwiftData
import UIKit

/// Full-screen take: live transcript, pace, fillers — then the result card.
struct RecordingView: View {
    let prompt: Prompt
    @Environment(SpeechEngine.self) private var engine
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("targetWPMLow") private var targetLow = 120.0
    @AppStorage("targetWPMHigh") private var targetHigh = 160.0

    @State private var result: SpeechAnalyzer.Analysis?
    @State private var finalTranscript = ""
    @State private var finalDuration: TimeInterval = 0
    @State private var saved = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.05, blue: 0.09).ignoresSafeArea()
                if let result {
                    ResultContent(analysis: result, transcript: finalTranscript,
                                  duration: finalDuration, saved: saved,
                                  onSave: save, onDiscard: { dismiss() })
                } else {
                    recordingContent
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(result == nil ? "Cancel" : "Close") {
                        if result == nil { engine.cancel() }
                        dismiss()
                    }
                    .tint(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(result == nil && engine.isRecording)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            engine.start()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            if engine.isRecording { engine.cancel() }
        }
    }

    @ViewBuilder
    private var recordingContent: some View {
        switch engine.state {
        case .denied(let message), .failed(let message):
            VStack(spacing: 16) {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.red)
                    .accessibilityHidden(true)
                Text("Can't record")
                    .font(Theme.display(24))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.violet)
            }
        case .requesting:
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(Theme.violet)
                Text("Getting the microphone ready…")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
        case .idle, .recording:
            liveView
        }
    }

    private var liveView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(prompt.title)
                    .font(Theme.display(20))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(prompt.text)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            if case .recording(let started) = engine.state {
                TimelineView(.periodic(from: .now, by: 1)) { timeline in
                    Text(elapsed(since: started, now: timeline.date))
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .accessibilityLabel("Recording for \(elapsed(since: started, now: timeline.date))")
                }
            }

            HStack(spacing: 14) {
                livePill(value: String(format: "%.0f", engine.liveWPM),
                         label: "wpm",
                         color: paceColor)
                livePill(value: "\(engine.liveFillerCount)", label: "fillers",
                         color: engine.liveFillerCount == 0 ? Theme.green : Theme.gold)
                livePill(value: "\(engine.liveWordCount)", label: "words", color: .white.opacity(0.7))
            }

            ScrollViewReader { proxy in
                ScrollView {
                    Text(engine.liveTranscript.isEmpty ? "Start talking — your words appear here." : engine.liveTranscript)
                        .font(.body)
                        .foregroundStyle(engine.liveTranscript.isEmpty ? .white.opacity(0.3) : .white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .id("transcript")
                }
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .onChange(of: engine.liveTranscript) {
                    proxy.scrollTo("transcript", anchor: .bottom)
                }
            }

            Button {
                Haptics.success()
                stop()
            } label: {
                Label("Finish take", systemImage: "stop.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.violet)
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            .disabled(!engine.isRecording)
        }
    }

    private var paceColor: Color {
        if engine.liveWPM <= 0 { return .white.opacity(0.7) }
        if engine.liveWPM < targetLow { return Theme.gold }
        if engine.liveWPM > targetHigh { return Theme.red }
        return Theme.green
    }

    private func livePill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(.white.opacity(0.07), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private func stop() {
        guard let finished = engine.finish() else { return }
        finalTranscript = finished.transcript
        finalDuration = finished.duration
        result = SpeechAnalyzer.analyze(transcript: finished.transcript,
                                        duration: finished.duration,
                                        targetWPMLow: targetLow,
                                        targetWPMHigh: targetHigh)
    }

    private func save() {
        guard let result, !saved else { return }
        let session = SpeechSession(duration: finalDuration,
                                    transcript: finalTranscript,
                                    promptTitle: prompt.title,
                                    wordCount: result.wordCount,
                                    fillerCount: result.fillerCount,
                                    wordsPerMinute: result.wordsPerMinute,
                                    vocabularyDiversity: result.vocabularyDiversity,
                                    score: result.score,
                                    fillerBreakdown: result.fillerBreakdown)
        context.insert(session)
        saved = true
        Haptics.success()
    }

    private func elapsed(since start: Date, now: Date) -> String {
        let s = max(Int(now.timeIntervalSince(start)), 0)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

/// Post-take result card (shared by RecordingView).
struct ResultContent: View {
    let analysis: SpeechAnalyzer.Analysis
    let transcript: String
    let duration: TimeInterval
    let saved: Bool
    let onSave: () -> Void
    let onDiscard: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ScoreBadge(score: analysis.score, size: 110)
                    .padding(.top, 12)
                VStack(spacing: 4) {
                    Text(SpeechAnalyzer.grade(forScore: analysis.score).label)
                        .font(Theme.display(26))
                        .foregroundStyle(.white)
                    Text(SpeechAnalyzer.grade(forScore: analysis.score).detail)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                HStack(spacing: 12) {
                    resultTile(value: SpeechAnalyzer.formatDuration(duration), label: "length")
                    resultTile(value: String(format: "%.0f", analysis.wordsPerMinute), label: "wpm")
                    resultTile(value: "\(analysis.fillerCount)", label: "fillers")
                    resultTile(value: String(format: "%.0f%%", analysis.vocabularyDiversity * 100), label: "variety")
                }
                .padding(.horizontal, 20)

                if !analysis.fillerBreakdown.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your fillers")
                            .font(.headline)
                            .foregroundStyle(.white)
                        ForEach(analysis.fillerBreakdown.sorted { $0.value > $1.value }, id: \.key) { word, count in
                            HStack {
                                Text("“\(word)”")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.gold)
                                Spacer()
                                Text("×\(count)")
                                    .font(.subheadline.weight(.bold))
                                    .monospacedDigit()
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                    }
                    .padding(16)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }

                if !transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcript")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(highlighted(transcript))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(16)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }

                VStack(spacing: 10) {
                    Button {
                        onSave()
                    } label: {
                        Label(saved ? "Saved to Sessions" : "Save session",
                              systemImage: saved ? "checkmark.circle.fill" : "tray.and.arrow.down.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(saved ? Theme.green : Theme.violet)
                    .disabled(saved)
                    Button("Discard take", role: .destructive) { onDiscard() }
                        .font(.subheadline)
                        .tint(Theme.red)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }

    private func resultTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private func highlighted(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.foregroundColor = .white.opacity(0.85)
        for range in SpeechAnalyzer.fillerRanges(in: text) {
            if let lower = AttributedString.Index(range.lowerBound, within: attributed),
               let upper = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[lower..<upper].foregroundColor = Theme.gold
                attributed[lower..<upper].font = .subheadline.weight(.bold)
            }
        }
        return attributed
    }
}
