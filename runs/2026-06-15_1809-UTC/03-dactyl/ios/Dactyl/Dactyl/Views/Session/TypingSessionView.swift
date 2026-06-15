import SwiftUI
import SwiftData

/// Full-screen typing drill. Renders the target text with per-character coloring + a caret,
/// a next-key + finger guide strip, a live HUD, and the hidden `KeyCaptureField` that raises
/// the keyboard. On completion it shows a result and writes a `TestResult` (+ lesson progress).
struct TypingSessionView: View {
    let config: SessionConfig

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var settings: AppSettings

    @StateObject private var vm: SessionViewModel
    @State private var keyboardActive = false
    @State private var didSave = false

    init(config: SessionConfig) {
        self.config = config
        _vm = StateObject(wrappedValue: SessionViewModel(config: config))
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if vm.finished {
                ResultView(
                    payload: vm.buildResultPayload(),
                    onRetry: retry,
                    onDone: { dismiss() }
                )
                .transition(.opacity)
            } else {
                sessionBody
                    .transition(.opacity)
            }
        }
        .navigationTitle(config.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Quit") { dismiss() }
            }
        }
        .onAppear {
            vm.start()
            keyboardActive = true
        }
        .onDisappear { vm.stopTimer() }
        .onChange(of: vm.finished) { _, isFinished in
            if isFinished {
                keyboardActive = false
                saveResultIfNeeded()
                Haptics.success(enabled: settings.hapticsEnabled)
            }
        }
    }

    // MARK: Live session

    private var sessionBody: some View {
        VStack(spacing: 18) {
            hud
            if settings.showFingerGuide {
                guideStrip
            }
            targetText
            Spacer(minLength: 0)
            captureArea
        }
        .padding(20)
    }

    private var hud: some View {
        HStack(spacing: 12) {
            StatPill(value: "\(Int(vm.wpm.rounded()))", label: "WPM", tint: Theme.accentDeep)
            Divider().frame(height: 30)
            StatPill(value: accuracyText, label: "Accuracy",
                     tint: vm.accuracy >= 0.95 ? Theme.good : Theme.ink)
            Divider().frame(height: 30)
            if let remaining = vm.secondsRemaining {
                StatPill(value: "\(remaining)s", label: "Left", tint: Theme.ink)
            } else {
                StatPill(value: timeText, label: "Time", tint: Theme.ink)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .cardSurface()
    }

    private var guideStrip: some View {
        HStack(spacing: 12) {
            if let ch = vm.engine.currentChar {
                Keycap(label: FingerMap.displayName(for: ch), size: 44, highlighted: true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next key")
                        .font(Theme.rounded(11, .semibold))
                        .foregroundStyle(Theme.inkFaint)
                        .textCase(.uppercase)
                    Text(FingerMap.fingerLabel(for: ch))
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                }
                Spacer()
            } else {
                Text("Done — nice work")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.good)
                Spacer()
            }
        }
        .padding(14)
        .cardSurface(fill: Theme.surfaceAlt)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(guideAccessibilityLabel)
    }

    private var guideAccessibilityLabel: String {
        if let ch = vm.engine.currentChar {
            return "Next key \(FingerMap.displayName(for: ch)), use \(FingerMap.fingerLabel(for: ch))"
        }
        return "Drill complete"
    }

    private var targetText: some View {
        ScrollView {
            TypingTextView(engine: vm.engine, blink: !reduceMotion)
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface()
        }
        .frame(maxHeight: 260)
    }

    private var captureArea: some View {
        ZStack {
            // The capture field is invisible but fills the tap area to keep the keyboard up.
            KeyCaptureField(
                isActive: $keyboardActive,
                onInsert: { ch in
                    vm.handleInsert(ch,
                                    hapticsEnabled: settings.hapticsEnabled,
                                    soundEnabled: settings.keySoundEnabled)
                },
                onDelete: { vm.handleDelete() }
            )
            .frame(height: 64)

            if vm.lastBlocked {
                strictBanner
            } else if !keyboardActive {
                tapToType
            }
        }
        .frame(height: 64)
        .contentShape(Rectangle())
        .onTapGesture { keyboardActive = true }
    }

    private var strictBanner: some View {
        Label("Fix the mistake to continue", systemImage: "delete.left.fill")
            .font(Theme.rounded(14, .semibold))
            .foregroundStyle(Theme.bad)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule().fill(Theme.bad.opacity(0.12)))
            .allowsHitTesting(false)
    }

    private var tapToType: some View {
        Label("Tap to bring up the keyboard", systemImage: "keyboard")
            .font(Theme.rounded(14, .semibold))
            .foregroundStyle(Theme.inkSoft)
            .allowsHitTesting(false)
    }

    // MARK: Derived strings

    private var accuracyText: String {
        "\(Int((vm.accuracy * 100).rounded()))%"
    }

    private var timeText: String {
        let s = Int(vm.elapsed.rounded())
        return "\(s)s"
    }

    // MARK: Actions

    private func retry() {
        // Reset the in-place view model to a fresh attempt of the same drill.
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
            vm.reset()
            didSave = false
        }
        keyboardActive = true
        vm.start()
    }

    private func saveResultIfNeeded() {
        guard !didSave else { return }
        didSave = true
        let payload = vm.buildResultPayload()

        let result = TestResult(
            mode: payload.mode,
            referenceTitle: payload.referenceTitle,
            wpm: payload.wpm,
            accuracy: payload.accuracy,
            durationSeconds: payload.durationSeconds,
            charCount: payload.charCount,
            errorCount: payload.errorCount,
            keyErrors: payload.keyErrors
        )
        modelContext.insert(result)

        if let lessonID = config.lessonID {
            updateLessonProgress(lessonID: lessonID, payload: payload)
        }
        try? modelContext.save()
    }

    private func updateLessonProgress(lessonID: String, payload: SessionResultPayload) {
        let descriptor = FetchDescriptor<LessonProgress>(
            predicate: #Predicate { $0.lessonID == lessonID }
        )
        let existing = (try? modelContext.fetch(descriptor))?.first
        let progress = existing ?? {
            let p = LessonProgress(lessonID: lessonID)
            modelContext.insert(p)
            return p
        }()
        progress.attempts += 1
        progress.lastPracticed = Date()
        if payload.wpm > progress.bestWPM { progress.bestWPM = payload.wpm }
        if payload.accuracy > progress.bestAccuracy { progress.bestAccuracy = payload.accuracy }
        // Mark complete when finished with solid accuracy.
        if payload.accuracy >= 0.90 { progress.completed = true }
    }
}
