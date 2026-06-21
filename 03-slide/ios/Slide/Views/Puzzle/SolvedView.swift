import SwiftUI
import SwiftData

struct SolvedView: View {
    let moves: Int
    let seconds: Double
    let size: Int
    let theme: String
    let onNewGame: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SlideTheme.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(SlideTheme.solved)
                Text("Puzzle Solved!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.white)
                HStack(spacing: 32) {
                    VStack {
                        Text("\(moves)")
                            .font(.title.bold())
                            .foregroundStyle(SlideTheme.accent)
                        Text("Moves")
                            .font(.caption)
                            .foregroundStyle(SlideTheme.textSecondary)
                    }
                    VStack {
                        Text(String(format: "%.0fs", seconds))
                            .font(.title.bold())
                            .foregroundStyle(SlideTheme.accent)
                        Text("Time")
                            .font(.caption)
                            .foregroundStyle(SlideTheme.textSecondary)
                    }
                }
                .padding()
                .background(SlideTheme.tileBg, in: .rect(cornerRadius: 16))
                Button("New Game") { onNewGame() }
                    .buttonStyle(.borderedProminent)
                    .tint(SlideTheme.accent)
                    .font(.headline)
                Button("Done") { dismiss() }
                    .foregroundStyle(SlideTheme.textSecondary)
            }
            .padding()
        }
    }
}
