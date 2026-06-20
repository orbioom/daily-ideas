import SwiftUI

struct HuntOnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            HuntTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3().tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == currentPage ? HuntTheme.accent : HuntTheme.secondaryText.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.top, 20)

                // Action button
                Button {
                    if currentPage < 2 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage < 2 ? "Next" : "Start Playing")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(HuntTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

private struct OnboardingPage1: View {
    let letters: [[Character]] = [
        ["W","O","R","D"],
        ["H","U","N","T"],
        ["P","L","A","Y"],
        ["F","I","N","E"]
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Find Words")
                .font(.largeTitle.bold())
                .foregroundStyle(HuntTheme.primaryText)

            Text("Spot words hidden in the 4x4 letter grid. The longer the word, the higher the score!")
                .font(.body)
                .foregroundStyle(HuntTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Mini grid preview
            VStack(spacing: 6) {
                ForEach(0..<4) { r in
                    HStack(spacing: 6) {
                        ForEach(0..<4) { c in
                            let letter = letters[r][c]
                            let isHighlighted = (r == 0 && c < 4) // highlight top row
                            Text(String(letter))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(isHighlighted ? Color.black : HuntTheme.primaryText)
                                .frame(width: 52, height: 52)
                                .background(isHighlighted ? HuntTheme.tileHighlight : HuntTheme.tileBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }

            Spacer()
        }
    }
}

private struct OnboardingPage2: View {
    @State private var animStep = 0

    let path = [(0,0),(0,1),(1,1),(2,2)]
    let letters: [[Character]] = [
        ["H","U","N","T"],
        ["A","N","E","R"],
        ["P","L","A","Y"],
        ["F","I","N","E"]
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Connect Letters")
                .font(.largeTitle.bold())
                .foregroundStyle(HuntTheme.primaryText)

            Text("Swipe to connect adjacent letters — up, down, left, right, or diagonal. Each letter can only be used once.")
                .font(.body)
                .foregroundStyle(HuntTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Animated grid
            VStack(spacing: 6) {
                ForEach(0..<4) { r in
                    HStack(spacing: 6) {
                        ForEach(0..<4) { c in
                            let isInPath = path.prefix(animStep + 1).contains(where: { $0.0 == r && $0.1 == c })
                            Text(String(letters[r][c]))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(isInPath ? Color.black : HuntTheme.primaryText)
                                .frame(width: 52, height: 52)
                                .background(isInPath ? HuntTheme.tileSelected : HuntTheme.tileBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .scaleEffect(isInPath ? 1.05 : 1.0)
                                .animation(.spring(duration: 0.3), value: isInPath)
                        }
                    }
                }
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                    animStep = (animStep + 1) % (path.count + 1)
                }
            }

            Spacer()
        }
    }
}

private struct OnboardingPage3: View {
    @State private var timeLeft = 120

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Beat the Clock")
                .font(.largeTitle.bold())
                .foregroundStyle(HuntTheme.primaryText)

            Text("You have 2 minutes to find as many words as possible. Score big with long words!")
                .font(.body)
                .foregroundStyle(HuntTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Timer display
            ZStack {
                Circle()
                    .stroke(HuntTheme.tileBackground, lineWidth: 12)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(timeLeft) / 120.0)
                    .stroke(HuntTheme.timerColor(for: timeLeft, total: 120), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timeLeft)

                VStack(spacing: 2) {
                    Text("\(timeLeft / 60):\(String(format: "%02d", timeLeft % 60))")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(HuntTheme.timerColor(for: timeLeft, total: 120))
                }
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if timeLeft > 0 {
                        timeLeft -= 1
                    } else {
                        timeLeft = 120
                    }
                }
            }

            // Score legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach([("3 letters", "1 pt"), ("4 letters", "2 pts"), ("5 letters", "4 pts"), ("6+ letters", "7+ pts")], id: \.0) { pair in
                    HStack {
                        Text(pair.0)
                            .foregroundStyle(HuntTheme.secondaryText)
                        Spacer()
                        Text(pair.1)
                            .foregroundStyle(HuntTheme.accent)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(HuntTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 48)

            Spacer()
        }
    }
}

#Preview {
    HuntOnboardingView(onComplete: {})
}
