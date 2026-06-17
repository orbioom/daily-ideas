import SwiftUI
import SwiftData

struct TracingCanvasView: View {
    let glyph: Glyph
    let profile: Profile
    /// The ordered list this glyph belongs to (for "Next").
    let queue: [Glyph]
    /// Called when the screen closes so the caller can refresh stars.
    let onFinished: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: TracingSession
    /// Position in `queue` (tracked by index so repeated letters sequence correctly).
    @State private var queueIndex: Int
    @State private var showResult = false
    @State private var resultStars = 0
    @State private var newBest = false
    @State private var confettiActive = false

    init(glyph: Glyph, profile: Profile, queue: [Glyph], onFinished: @escaping () -> Void) {
        self.glyph = glyph
        self.profile = profile
        self.queue = queue
        self.onFinished = onFinished
        _session = State(initialValue: TracingSession(glyph: glyph))
        // Start at the first occurrence of this glyph in the queue (or 0).
        _queueIndex = State(initialValue: queue.firstIndex(of: glyph) ?? 0)
    }

    private var noFail: Bool { isPro && settings.noFailMode }

    /// The glyph currently being traced (may differ from the initial `glyph`
    /// after advancing through the practice queue).
    private var currentGlyph: Glyph { session.glyph }

    private var nextGlyph: Glyph? {
        let nextIdx = queueIndex + 1
        guard queue.indices.contains(nextIdx) else { return nil }
        return queue[nextIdx]
    }

    var body: some View {
        ZStack {
            WarmBackground()
            VStack(spacing: 12) {
                header
                instruction
                canvasCard
                controls
            }
            .padding(20)

            if showResult {
                resultOverlay
            }
            ConfettiView(isActive: confettiActive)
                .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button {
                onFinished()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.inkSoft)
            }
            .accessibilityLabel("Close")

            Spacer()

            VStack(spacing: 2) {
                Text(currentGlyph.display)
                    .font(Theme.rounded(34, .heavy))
                    .foregroundStyle(Theme.accent)
                Text(currentGlyph.label)
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }

            Spacer()

            // Stroke progress pips.
            HStack(spacing: 5) {
                ForEach(0..<session.totalStrokes, id: \.self) { i in
                    Circle()
                        .fill(session.completedStrokes.contains(i) ? Theme.good : Theme.hairline)
                        .frame(width: 10, height: 10)
                }
            }
            .accessibilityLabel("\(session.completedStrokes.count) of \(session.totalStrokes) strokes done")
        }
    }

    private var instruction: some View {
        Label {
            Text(instructionText)
        } icon: {
            Image(systemName: settings.leftHanded ? "hand.point.left.fill" : "hand.point.right.fill")
        }
        .font(Theme.rounded(15, .semibold))
        .foregroundStyle(Theme.inkSoft)
        .multilineTextAlignment(.center)
    }

    private var instructionText: String {
        if noFail { return "No-fail mode: just have fun!" }
        return "Start at the orange dot and follow the road!"
    }

    // MARK: - Canvas

    private var canvasCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 5)
            TraceCanvas(
                session: session,
                guideStyle: settings.guideStyle,
                inkColor: settings.inkColor.color,
                leftHanded: settings.leftHanded,
                onStrokeEnded: handleStrokeEnded
            )
            .padding(16)
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: 1)
        )
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 12) {
            ChunkyButton(title: "Clear", systemImage: "arrow.counterclockwise", style: .soft) {
                Haptics.impact(.light, enabled: settings.hapticsEnabled)
                session.reset()
            }
            ChunkyButton(title: "Check", systemImage: "checkmark", style: .primary) {
                finishAttempt()
            }
            .disabled(!session.allStrokesDone && !noFail)
            .opacity((!session.allStrokesDone && !noFail) ? 0.55 : 1)
            .accessibilityHint(session.allStrokesDone || noFail ? "Scores your tracing" : "Finish all strokes first")
        }
    }

    // MARK: - Result overlay

    private var resultOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(resultStars > 0 ? "Great job!" : "Almost!")
                    .font(Theme.rounded(30, .heavy))
                    .foregroundStyle(Theme.ink)

                StarRatingView(count: resultStars, size: 44, animated: true)

                if newBest && resultStars > 0 {
                    Label("New best!", systemImage: "trophy.fill")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(Capsule().fill(Theme.star))
                }

                Text(resultStars > 0 ? messageFor(resultStars) : "Give it another try — you've got this!")
                    .font(Theme.rounded(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                VStack(spacing: 10) {
                    ChunkyButton(title: "Try again", systemImage: "arrow.counterclockwise", style: .soft) {
                        retry()
                    }
                    if let next = nextGlyph {
                        ChunkyButton(title: "Next: \(next.display)", systemImage: "arrow.right", style: .primary) {
                            goNext(next)
                        }
                    } else {
                        ChunkyButton(title: "Done", systemImage: "checkmark", style: .primary) {
                            onFinished()
                            dismiss()
                        }
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusLarge, style: .continuous)
                    .fill(Theme.surface)
            )
            .padding(24)
        }
        .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
    }

    private func messageFor(_ stars: Int) -> String {
        switch stars {
        case 3: return "Perfect tracing — three shiny stars!"
        case 2: return "Really good! Try once more for three stars."
        default: return "Nice start! Stay on the road for more stars."
        }
    }

    // MARK: - Logic

    private func handleStrokeEnded() {
        session.endStroke(noFail: noFail)
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
        // Auto-check when the child completes the last stroke.
        if session.allStrokesDone {
            finishAttempt()
        }
    }

    private func finishAttempt() {
        let result = session.finalize(noFail: noFail)
        resultStars = result.stars
        newBest = ProgressService.record(
            profileID: profile.id,
            glyphKey: currentGlyph.key,
            stars: result.stars,
            context: context
        )

        if result.stars > 0 {
            Haptics.success(enabled: settings.hapticsEnabled)
            SoundPlayer.success(enabled: settings.soundEnabled)
            confettiActive = false
            withAnimation { confettiActive = true }
        } else {
            Haptics.warning(enabled: settings.hapticsEnabled)
            SoundPlayer.tryAgain(enabled: settings.soundEnabled)
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showResult = true
        }
    }

    private func retry() {
        withAnimation { showResult = false }
        confettiActive = false
        session.reset()
        Haptics.impact(.light, enabled: settings.hapticsEnabled)
    }

    private func goNext(_ next: Glyph) {
        withAnimation { showResult = false }
        confettiActive = false
        queueIndex += 1
        session = TracingSession(glyph: next)
        // The screen is presented via fullScreenCover(item:); replacing the
        // session (and advancing the index) retargets within this screen.
    }
}
