import SwiftUI

struct QuizResultView: View {
    let engine: QuizEngine
    let onDone: () -> Void
    let onRestart: () -> Void

    private var accuracy: Int {
        guard engine.questionsAnswered > 0 else { return 0 }
        return Int(Double(engine.correctCount) / Double(engine.questionsAnswered) * 100)
    }

    private var grade: (label: String, color: Color, icon: String) {
        switch accuracy {
        case 90...100: return ("Excellent!", AtomTheme.success, "star.fill")
        case 70..<90:  return ("Great Job!", AtomTheme.accent, "hand.thumbsup.fill")
        case 50..<70:  return ("Good Try!", AtomTheme.warning, "bolt.fill")
        default:       return ("Keep Studying", AtomTheme.error, "book.fill")
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 16)

                // Grade badge
                VStack(spacing: 12) {
                    Image(systemName: grade.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(grade.color)

                    Text(grade.label)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(AtomTheme.textPrimary)

                    Text("\(accuracy)% Accuracy")
                        .font(.headline)
                        .foregroundStyle(grade.color)
                }

                // Score card
                VStack(spacing: 0) {
                    resultRow(icon: "checkmark.circle.fill", label: "Correct", value: "\(engine.correctCount)", color: AtomTheme.success)
                    Divider().background(AtomTheme.cellBorder).padding(.horizontal, 16)
                    resultRow(icon: "xmark.circle.fill", label: "Incorrect", value: "\(engine.wrongCount)", color: AtomTheme.error)
                    Divider().background(AtomTheme.cellBorder).padding(.horizontal, 16)
                    resultRow(icon: "flame.fill", label: "Best Streak", value: "\(engine.bestStreak)", color: AtomTheme.warning)
                    Divider().background(AtomTheme.cellBorder).padding(.horizontal, 16)
                    resultRow(icon: "number.circle.fill", label: "Questions", value: "\(engine.questionsAnswered)", color: AtomTheme.accent)
                }
                .background(AtomTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AtomTheme.cornerRadius))
                .padding(.horizontal, 24)

                // Missed elements
                if !engine.mostMissedElements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Review These")
                            .font(.headline)
                            .foregroundStyle(AtomTheme.textSecondary)
                            .padding(.horizontal, 24)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(engine.mostMissedElements) { el in
                                    VStack(spacing: 4) {
                                        ElementCellView(element: el, width: 52, height: 62)
                                        Text(el.name)
                                            .font(.system(size: 9))
                                            .foregroundStyle(AtomTheme.textSecondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                }

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        onRestart()
                    } label: {
                        Label("Play Again", systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AtomButtonStyle())

                    Button {
                        onDone()
                    } label: {
                        Text("Back to Modes")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AtomButtonStyle(filled: false))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .background(AtomTheme.background)
        .navigationTitle("Results")
        .navigationBarBackButtonHidden(true)
    }

    private func resultRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .foregroundStyle(AtomTheme.textSecondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(AtomTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        QuizResultView(
            engine: {
                let e = QuizEngine()
                e.correctCount = 7
                e.wrongCount = 3
                e.questionsAnswered = 10
                e.bestStreak = 5
                return e
            }(),
            onDone: {},
            onRestart: {}
        )
    }
    .preferredColorScheme(.dark)
}
