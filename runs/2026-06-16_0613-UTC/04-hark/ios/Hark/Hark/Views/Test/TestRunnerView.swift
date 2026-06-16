import SwiftUI
import SwiftData

struct TestRunnerView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var model: TestRunnerModel?
    @State private var showQuitConfirm = false
    @State private var savedTest: HearingTest?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if let model {
                    content(model)
                } else {
                    ProgressView("Preparing tones…")
                        .tint(Theme.accent)
                        .font(Theme.rounded(15))
                }
            }
            .navigationDestination(item: $savedTest) { test in
                ResultsView(test: test)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { dismiss() }
                                .font(Theme.rounded(16, .semibold))
                        }
                    }
            }
        }
        .onAppear {
            if model == nil {
                let m = TestRunnerModel(settings: settings)
                model = m
                m.begin()
            }
        }
        .onDisappear { model?.teardown() }
        .interactiveDismissDisabled(true)
    }

    @ViewBuilder
    private func content(_ model: TestRunnerModel) -> some View {
        switch model.phase {
        case .error(let message):
            errorView(message)
        case .finished:
            finishedView(model)
        default:
            runningView(model)
        }
    }

    // MARK: Running

    private func runningView(_ model: TestRunnerModel) -> some View {
        VStack(spacing: 0) {
            topBar(model)

            Spacer()

            VStack(spacing: 8) {
                Text(model.currentEar.rawValue + " ear")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(model.currentEar == .right ? Theme.earRight : Theme.earLeft)
                Text(Audiometry.label(forFrequency: model.currentFrequency))
                    .font(Theme.rounded(34, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Tap the button the moment you hear a tone")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Testing \(model.currentEar.rawValue) ear at \(Audiometry.label(forFrequency: model.currentFrequency)).")

            Spacer()

            hearButton(model)

            Spacer()

            if model.isPaused {
                Text("Paused")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.warn)
                    .transition(.opacity)
            }

            progressBar(model)
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
        }
        .padding(.top, 8)
        .confirmationDialog("Quit this screening?", isPresented: $showQuitConfirm, titleVisibility: .visible) {
            Button("Quit without saving", role: .destructive) {
                model.quit()
                dismiss()
            }
            Button("Keep going", role: .cancel) { }
        } message: {
            Text("Your progress so far won't be saved.")
        }
    }

    private func topBar(_ model: TestRunnerModel) -> some View {
        HStack {
            Button {
                showQuitConfirm = true
            } label: {
                Image(systemName: "xmark")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Quit screening")

            Spacer()

            Text("Hearing check")
                .font(Theme.rounded(16, .semibold))
                .foregroundStyle(Theme.ink)

            Spacer()

            Button {
                Haptics.selection(enabled: settings.hapticsEnabled)
                withAnimation(reduceMotion ? nil : .easeInOut) { model.togglePause() }
            } label: {
                Image(systemName: model.isPaused ? "play.fill" : "pause.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(model.isPaused ? "Resume" : "Pause")
        }
        .padding(.horizontal, 12)
    }

    private func hearButton(_ model: TestRunnerModel) -> some View {
        Button {
            Haptics.impact(.medium, enabled: settings.hapticsEnabled)
            model.userHeard()
        } label: {
            ZStack {
                // Subtle pulse only while the tone is audible, suppressed under Reduce Motion.
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 220, height: 220)
                    .scaleEffect(model.toneAudible && !reduceMotion ? 1.06 : 1.0)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                               value: model.toneAudible)
                Circle()
                    .fill(Theme.heroGradient)
                    .frame(width: 184, height: 184)
                VStack(spacing: 6) {
                    Image(systemName: "ear")
                        .font(.system(size: 38, weight: .semibold))
                    Text("I hear a tone")
                        .font(Theme.rounded(19, .bold))
                }
                .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .disabled(model.isPaused)
        .accessibilityLabel("I hear a tone")
        .accessibilityHint("Double-tap the instant you hear a beep.")
        .accessibilityAddTraits(.isButton)
    }

    private func progressBar(_ model: TestRunnerModel) -> some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.hairline)
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: max(6, geo.size.width * model.progress))
                        .animation(reduceMotion ? nil : .easeInOut, value: model.progress)
                }
            }
            .frame(height: 8)
            Text("\(Int(model.progress * 100))% complete")
                .font(Theme.rounded(13))
                .foregroundStyle(Theme.inkSoft)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(model.progress * 100)) percent complete")
    }

    // MARK: Finished

    private func finishedView(_ model: TestRunnerModel) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    Circle().fill(Theme.good.opacity(0.18)).frame(width: 96, height: 96)
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Theme.good)
                }
                .accessibilityHidden(true)

                Text("Screening complete")
                    .font(Theme.rounded(26, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Nicely done. Here's your audiogram.")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)

                Card {
                    AudiogramChart(
                        leftThresholds: model.results[.left] ?? [:],
                        rightThresholds: model.results[.right] ?? [:],
                        maxLevel: settings.maxTestLevel
                    )
                    AudiogramLegend().padding(.top, 8)
                }

                PrimaryButton(title: "Save & view results", systemImage: "tray.and.arrow.down") {
                    if let test = model.save(into: context) {
                        Haptics.success(enabled: settings.hapticsEnabled)
                        savedTest = test
                    }
                }
                Button("Discard") {
                    model.quit()
                    dismiss()
                }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
            }
            .padding(24)
        }
    }

    // MARK: Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 44))
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
            Text("We couldn't start the tones")
                .font(Theme.rounded(22, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(message)
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Try again", systemImage: "arrow.clockwise") {
                let m = TestRunnerModel(settings: settings)
                model = m
                m.begin()
            }
            Button("Close") { dismiss() }
                .font(Theme.rounded(15, .medium))
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(28)
    }
}
