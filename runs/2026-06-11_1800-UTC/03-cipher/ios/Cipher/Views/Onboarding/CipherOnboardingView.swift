import SwiftUI

struct CipherOnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = [
        ("lock.open.fill", "A Daily Word Puzzle", "Each day brings a new quote encoded in a substitution cipher. Your mission: decode it letter by letter."),
        ("hand.tap.fill", "Tap to Decode", "Tap any cipher letter to select it, then tap the real letter you think it represents. All instances reveal instantly."),
        ("chart.line.uptrend.xyaxis", "Track Your Streak", "Solve a puzzle every day to build your streak. Use hints sparingly — each one costs you a perfect score.")
    ]

    var body: some View {
        ZStack {
            CipherTheme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        let p = pages[i]
                        VStack(spacing: 32) {
                            Spacer()
                            Image(systemName: p.0)
                                .font(.system(size: 80))
                                .foregroundStyle(CipherTheme.amber)
                                .accessibilityHidden(true)
                            VStack(spacing: 12) {
                                Text(p.1)
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(CipherTheme.text)
                                    .multilineTextAlignment(.center)
                                Text(p.2)
                                    .font(.body)
                                    .foregroundStyle(CipherTheme.subtle)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            Spacer()
                        }.tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            Capsule()
                                .fill(i == page ? CipherTheme.amber : CipherTheme.subtle.opacity(0.3))
                                .frame(width: i == page ? 24 : 8, height: 8)
                                .animation(reduceMotion ? .none : .spring(response: 0.3), value: page)
                        }
                    }
                    Button(page < pages.count - 1 ? "Next" : "Start Solving") {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? .none : .easeInOut) { page += 1 }
                        } else { isComplete = true }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(CipherTheme.amber)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }
}
