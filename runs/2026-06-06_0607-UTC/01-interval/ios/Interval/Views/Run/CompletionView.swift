import SwiftUI

/// The success state shown when a run finishes (or is ended). Summarises the run before
/// returning to the library.
struct CompletionView: View {
    let engine: WorkoutEngine
    let routineName: String
    var onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var finishedFully: Bool {
        engine.completedSteps >= engine.steps.count && engine.steps.count > 0
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Brand.live.opacity(0.16))
                    .frame(width: 120, height: 120)
                Image(systemName: finishedFully ? "checkmark" : "flag.checkered")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Brand.live)
            }
            .scaleEffect(appeared || reduceMotion ? 1 : 0.7)
            .opacity(appeared || reduceMotion ? 1 : 0)
            .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text(finishedFully ? "Run complete" : "Run ended")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Brand.text)
                Text(routineName)
                    .font(.headline.weight(.regular))
                    .foregroundStyle(Brand.text2)
            }

            GlassCard {
                HStack(spacing: 0) {
                    StatBlock(value: DurationFormat.compact(engine.elapsedActiveForDisplay),
                              label: "Active")
                    Divider().frame(height: 36)
                    StatBlock(value: DurationFormat.compact(workSeconds),
                              label: "Work", tint: Brand.live)
                    Divider().frame(height: 36)
                    StatBlock(value: "\(engine.completedSteps)/\(engine.steps.count)",
                              label: "Steps")
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            InkButton(title: "Done", systemImage: "checkmark") {
                onDone()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            if reduceMotion { appeared = true }
            else { withAnimation(Brand.ease(0.5)) { appeared = true } }
        }
    }

    private var workSeconds: Int {
        engine.steps.prefix(engine.completedSteps)
            .filter { $0.kind == .work }
            .reduce(0) { $0 + $1.duration }
    }
}
