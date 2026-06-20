import SwiftUI

struct MeaningQuizView: View {
    let word: HskWord
    let onResult: (Bool) -> Void

    @State private var options: [HskWord] = []
    @State private var selectedId: Int? = nil
    @State private var hasAnswered = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Character prompt
            VStack(spacing: 12) {
                Text(word.character)
                    .font(.system(size: 100, weight: .thin))
                    .foregroundStyle(ShuTheme.primaryText)

                Text("What does this mean?")
                    .font(ShuTheme.labelFont(size: 15))
                    .foregroundStyle(ShuTheme.subtleText)
            }

            Spacer()

            // Answer options
            VStack(spacing: 12) {
                ForEach(options) { option in
                    optionButton(option: option)
                }
            }
            .padding(.horizontal, 24)

            if hasAnswered {
                feedbackRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer(minLength: 40)
        }
        .onAppear { buildOptions() }
        .onChange(of: word.id) {
            selectedId = nil
            hasAnswered = false
            buildOptions()
        }
    }

    // MARK: - Option Button
    private func optionButton(option: HskWord) -> some View {
        let isCorrect = option.id == word.id
        let isSelected = selectedId == option.id

        let bgColor: Color = {
            if !hasAnswered { return Color.white.opacity(0.05) }
            if isCorrect { return ShuTheme.correctGreen.opacity(0.18) }
            if isSelected { return ShuTheme.wrongRed.opacity(0.18) }
            return Color.white.opacity(0.03)
        }()

        let borderColor: Color = {
            if !hasAnswered { return Color.white.opacity(0.12) }
            if isCorrect { return ShuTheme.correctGreen }
            if isSelected { return ShuTheme.wrongRed }
            return Color.white.opacity(0.06)
        }()

        return Button {
            guard !hasAnswered else { return }
            selectedId = option.id
            withAnimation { hasAnswered = true }
            SpeechManager.speak(word.character)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                onResult(isCorrect)
            }
        } label: {
            HStack {
                Text(option.english)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(ShuTheme.primaryText)
                    .multilineTextAlignment(.leading)
                Spacer()
                if hasAnswered {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : ""))
                        .font(.system(size: 18))
                        .foregroundStyle(isCorrect ? ShuTheme.correctGreen : ShuTheme.wrongRed)
                        .opacity(isCorrect || isSelected ? 1 : 0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(bgColor)
            .overlay(
                RoundedRectangle(cornerRadius: ShuTheme.buttonRadius)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: ShuTheme.buttonRadius))
        }
        .disabled(hasAnswered)
    }

    // MARK: - Feedback
    private var feedbackRow: some View {
        let correct = selectedId == word.id
        return HStack(spacing: 12) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(correct ? ShuTheme.correctGreen : ShuTheme.wrongRed)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(correct ? "Correct!" : "Incorrect")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(correct ? ShuTheme.correctGreen : ShuTheme.wrongRed)
                Text("\(word.character) means \"\(word.english)\"")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(ShuTheme.subtleText)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    // MARK: - Build Options
    private func buildOptions() {
        var pool = hskWords.filter { $0.id != word.id }.shuffled()
        let distractors = Array(pool.prefix(3))
        options = (distractors + [word]).shuffled()
    }
}

#Preview {
    ZStack {
        ShuTheme.darkNavy.ignoresSafeArea()
        MeaningQuizView(word: hskWords[5], onResult: { _ in })
    }
}
