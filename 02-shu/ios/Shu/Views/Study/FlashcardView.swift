import SwiftUI

struct FlashcardView: View {
    let word: HskWord
    let onRate: (Int) -> Void

    @State private var isRevealed = false
    @State private var flipAngle: Double = 0
    @State private var showFront = true

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Card
            ZStack {
                if showFront {
                    frontCard
                        .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0))
                } else {
                    backCard
                        .rotation3DEffect(.degrees(flipAngle - 180), axis: (x: 0, y: 1, z: 0))
                }
            }
            .frame(height: 340)
            .padding(.horizontal, 24)
            .onTapGesture {
                guard !isRevealed else { return }
                reveal()
            }

            Spacer()

            // Rating buttons (only shown when revealed)
            if isRevealed {
                ratingButtons
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("Tap the card to reveal")
                    .font(ShuTheme.labelFont(size: 14))
                    .foregroundStyle(ShuTheme.subtleText)
                    .padding(.bottom, 48)
            }
        }
        .onChange(of: word.id) {
            // Reset for new card
            isRevealed = false
            flipAngle = 0
            showFront = true
        }
    }

    // MARK: - Front Card
    private var frontCard: some View {
        VStack(spacing: 16) {
            Spacer()

            Text(word.character)
                .font(.system(size: 96, weight: .thin))
                .foregroundStyle(ShuTheme.primaryText)

            Text(word.english)
                .font(ShuTheme.labelFont(size: 16))
                .foregroundStyle(ShuTheme.subtleText)
                .opacity(0)   // invisible spacer so layout is stable

            Spacer()

            Text("Tap to reveal")
                .font(ShuTheme.labelFont(size: 13))
                .foregroundStyle(ShuTheme.subtleText)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    // MARK: - Back Card
    private var backCard: some View {
        VStack(spacing: 12) {
            Spacer()

            Text(word.character)
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(ShuTheme.primaryText)

            // Pinyin with tone color
            Text(word.pinyin)
                .font(ShuTheme.pinyinFont(size: 26))
                .foregroundStyle(ShuTheme.toneColor(for: word.tone))

            Text(word.english)
                .font(.system(size: 22, weight: .medium, design: .rounded))
                .foregroundStyle(ShuTheme.primaryText)

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 32)
                .padding(.vertical, 4)

            VStack(spacing: 4) {
                Text(word.exampleSentence)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(ShuTheme.secondaryText)
                Text(word.exampleTranslation)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(ShuTheme.subtleText)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            // Speaker button
            Button {
                SpeechManager.speak(word.character)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(ShuTheme.gold)
                    .padding(12)
                    .background(ShuTheme.gold.opacity(0.15))
                    .clipShape(Circle())
            }
            .padding(.top, 4)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: ShuTheme.cardRadius)
            .fill(ShuTheme.cardBg)
            .shadow(color: ShuTheme.cardShadow, radius: 16, x: 0, y: 8)
    }

    // MARK: - Reveal
    private func reveal() {
        withAnimation(.easeInOut(duration: 0.4)) {
            flipAngle = 90
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showFront = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.4)) {
                flipAngle = 180
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation { isRevealed = true }
            SpeechManager.speak(word.character)
        }
    }

    // MARK: - Rating Buttons
    private var ratingButtons: some View {
        VStack(spacing: 12) {
            Text("How well did you know this?")
                .font(ShuTheme.labelFont(size: 13))
                .foregroundStyle(ShuTheme.subtleText)

            HStack(spacing: 10) {
                ratingButton(label: "Again", sublabel: "< 1 day", rating: 0, color: ShuTheme.wrongRed)
                ratingButton(label: "Hard",  sublabel: "~3 days",  rating: 3, color: ShuTheme.warningAmber)
                ratingButton(label: "Good",  sublabel: "~1 week",  rating: 4, color: ShuTheme.correctGreen)
                ratingButton(label: "Easy",  sublabel: "~2 weeks", rating: 5, color: Color(red: 0.35, green: 0.70, blue: 0.96))
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 48)
        }
    }

    private func ratingButton(label: String, sublabel: String, rating: Int, color: Color) -> some View {
        Button {
            onRate(rating)
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                Text(sublabel)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(color.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: ShuTheme.buttonRadius)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: ShuTheme.buttonRadius))
        }
    }
}

#Preview {
    ZStack {
        ShuTheme.darkNavy.ignoresSafeArea()
        FlashcardView(word: hskWords[0], onRate: { _ in })
    }
}
