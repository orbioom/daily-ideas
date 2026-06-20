import SwiftUI

struct ToneQuizView: View {
    let word: HskWord
    let onResult: (Bool) -> Void

    @State private var selectedTone: Int? = nil
    @State private var hasAnswered = false

    private let toneLabels = ["Tone 1 ¯", "Tone 2 ´", "Tone 3 ˇ", "Tone 4 `"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Character display (no tone marks on pinyin)
            VStack(spacing: 12) {
                Text(word.character)
                    .font(.system(size: 100, weight: .thin))
                    .foregroundStyle(ShuTheme.primaryText)

                Text(word.pinyinNoTone)
                    .font(ShuTheme.pinyinFont(size: 24))
                    .foregroundStyle(ShuTheme.subtleText)

                Text("Which tone is this character?")
                    .font(ShuTheme.labelFont(size: 15))
                    .foregroundStyle(ShuTheme.subtleText)
                    .padding(.top, 4)
            }

            Spacer()

            // Tone buttons
            VStack(spacing: 12) {
                ForEach(1...4, id: \.self) { tone in
                    toneButton(tone: tone)
                }
            }
            .padding(.horizontal, 24)

            // Feedback / advance
            if hasAnswered {
                feedbackRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Spacer(minLength: 40)
        }
        .onChange(of: word.id) {
            selectedTone = nil
            hasAnswered = false
        }
    }

    // MARK: - Tone Button
    private func toneButton(tone: Int) -> some View {
        let isCorrect = tone == word.tone
        let isSelected = selectedTone == tone
        let color = ShuTheme.toneColor(for: tone)

        let bgColor: Color = {
            if !hasAnswered {
                return color.opacity(0.12)
            }
            if isCorrect { return ShuTheme.correctGreen.opacity(0.18) }
            if isSelected { return ShuTheme.wrongRed.opacity(0.18) }
            return color.opacity(0.06)
        }()

        let borderColor: Color = {
            if !hasAnswered { return isSelected ? color : color.opacity(0.3) }
            if isCorrect { return ShuTheme.correctGreen }
            if isSelected { return ShuTheme.wrongRed }
            return color.opacity(0.15)
        }()

        return Button {
            guard !hasAnswered else { return }
            selectedTone = tone
            withAnimation {
                hasAnswered = true
            }
            // Brief delay then auto-advance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                onResult(isCorrect)
            }
        } label: {
            HStack(spacing: 16) {
                // Tone diacritic sample
                Text(toneLabels[tone - 1])
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .frame(width: 80, alignment: .leading)

                Divider()
                    .background(color.opacity(0.2))
                    .frame(height: 24)

                Text(toneMnemonic(tone))
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(ShuTheme.secondaryText)

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

    private func toneMnemonic(_ tone: Int) -> String {
        switch tone {
        case 1: return "High & flat (ā)"
        case 2: return "Rising, like a question (á)"
        case 3: return "Dip then rise (ǎ)"
        case 4: return "Sharp falling (à)"
        default: return "Neutral (a)"
        }
    }

    // MARK: - Feedback Row
    private var feedbackRow: some View {
        let correct = selectedTone == word.tone
        return HStack(spacing: 12) {
            Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(correct ? ShuTheme.correctGreen : ShuTheme.wrongRed)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 2) {
                Text(correct ? "Correct!" : "Incorrect")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(correct ? ShuTheme.correctGreen : ShuTheme.wrongRed)
                Text("It's \(word.pinyin) — Tone \(word.tone)")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(ShuTheme.subtleText)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}

#Preview {
    ZStack {
        ShuTheme.darkNavy.ignoresSafeArea()
        ToneQuizView(word: hskWords[0], onResult: { _ in })
    }
}
