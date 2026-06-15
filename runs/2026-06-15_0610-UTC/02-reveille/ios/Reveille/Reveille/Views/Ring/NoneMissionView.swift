import SwiftUI

/// The simplest mission: a single, deliberate Stop button (held briefly so a sleepy thumb
/// can't dismiss by accident). Best for light sleepers.
struct NoneMissionView: View {
    let onComplete: () -> Void
    @State private var progress: Double = 0
    @State private var holding = false
    private let holdDuration: Double = 1.0
    private let tick = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()

    var body: some View {
        MissionShell(title: "Stop the alarm",
                     subtitle: "Press and hold the button to turn it off.",
                     repsTotal: 1, repsDone: 0) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "power")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 150, height: 150)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in holding = true }
                    .onEnded { _ in holding = false; progress = 0 }
            )
            .accessibilityLabel("Hold to stop the alarm")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onComplete() }
        }
        .onReceive(tick) { _ in
            guard holding else { return }
            progress = min(1, progress + 0.03 / holdDuration)
            if progress >= 1 {
                holding = false
                onComplete()
            }
        }
    }
}
