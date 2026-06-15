import SwiftUI

/// A blink-rate trainer: a soft circle gently expands and contracts to pace full blinks.
/// "Close" on the contraction, "open" on the expansion. Reduce Motion → a still, text-paced cue.
struct BlinkTrainerView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var settings: AppSettings

    @State private var running = false
    @State private var anchor: Date = .now
    @State private var blinkCount = 0
    @State private var closedPhase = false

    /// One full blink cycle every `period` seconds (a relaxed ~6 blinks/min pace).
    private let period: Double = 5

    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.restGradient(scheme).ignoresSafeArea()
            VStack(spacing: 26) {
                header
                Spacer()
                pacer
                counter
                Spacer()
                controls
            }
            .padding(20)
        }
        .navigationTitle("Blink trainer")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(ticker) { _ in
            guard running else { return }
            tick()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Blink fully")
                .font(Theme.rounded(22, .bold)).foregroundStyle(Theme.ink)
            Text("Screens cut our blink rate and dry the eyes. Follow the rhythm and let each blink fully close.")
                .font(Theme.rounded(14)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var pacer: some View {
        if reduceMotion {
            VStack(spacing: 14) {
                Image(systemName: running && closedPhase ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(running ? (closedPhase ? "Close…" : "Open") : "Ready")
                    .font(Theme.rounded(20, .bold)).foregroundStyle(Theme.accent)
                    .accessibilityLabel(running ? (closedPhase ? "Close your eyes" : "Open your eyes") : "Ready")
            }
            .frame(height: 200)
        } else {
            TimelineView(.animation) { context in
                let t = running ? context.date.timeIntervalSince(anchor) : 0
                // 0..1 within the cycle; contract toward the close point.
                let cyclePos = (t / period).truncatingRemainder(dividingBy: 1)
                // A smooth ease: large most of the time, quick squeeze near the close.
                let openness = 0.5 + 0.5 * cos(cyclePos * 2 * .pi) // 1 = open, 0 = closed
                let dim: CGFloat = CGFloat(90 + 90 * openness)
                ZStack {
                    Circle()
                        .fill(Theme.teal.opacity(0.18))
                        .frame(width: dim + 40, height: dim + 40)
                    Circle()
                        .fill(Theme.heroGradient)
                        .frame(width: dim, height: dim)
                    Text(openness < 0.25 ? "Close" : "Open")
                        .font(Theme.rounded(18, .bold))
                        .foregroundStyle(.white)
                }
                .frame(height: 220)
                .accessibilityHidden(true)
            }
        }
    }

    private var counter: some View {
        Text(running ? "\(blinkCount) blinks" : (blinkCount > 0 ? "\(blinkCount) blinks done" : "Tap start to begin"))
            .font(Theme.rounded(15, .medium)).foregroundStyle(Theme.inkSoft)
            .accessibilityLabel("\(blinkCount) blinks")
    }

    private var controls: some View {
        Group {
            if running {
                SecondaryButton(title: "Stop", systemImage: "stop.fill") { stop() }
            } else {
                PrimaryButton(title: blinkCount > 0 ? "Start again" : "Start", systemImage: "play.fill") { start() }
            }
        }
    }

    private func start() {
        blinkCount = 0
        closedPhase = false
        anchor = .now
        running = true
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func stop() {
        running = false
        Haptics.tap(enabled: settings.hapticsEnabled)
    }

    private func tick() {
        let cyclePos = (Date.now.timeIntervalSince(anchor) / period).truncatingRemainder(dividingBy: 1)
        let nowClosed = cyclePos > 0.45 && cyclePos < 0.55
        if nowClosed && !closedPhase {
            closedPhase = true
            blinkCount += 1
            Haptics.selection(enabled: settings.hapticsEnabled)
        } else if !nowClosed {
            closedPhase = false
        }
    }
}
