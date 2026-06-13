import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    intro.tag(0)
                    howTo.tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button {
                    if page < 1 { withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 } }
                    else { hasOnboarded = true; Haptics.success() }
                } label: {
                    Text(page < 1 ? "How to play" : "Play")
                        .font(.system(size: 17, weight: .bold)).frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accent))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24).padding(.bottom, 20)
            }
        }
    }

    private var intro: some View {
        VStack(spacing: 22) {
            Spacer()
            HStack(spacing: 8) {
                ForEach(Array("LEXIS".enumerated()), id: \.offset) { i, ch in
                    let colors = [Theme.correct, Theme.present, Theme.absent, Theme.correct, Theme.absent]
                    Text(String(ch)).font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(RoundedRectangle(cornerRadius: 8).fill(colors[i]))
                }
            }
            Text("Lexicon").font(Theme.rounded(34)).foregroundStyle(Theme.ink)
            Text("Guess the five-letter word in six tries. A fresh puzzle every day, plus unlimited practice and the full archive — free, with no ads.")
                .font(.system(size: 17)).foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center).padding(.horizontal, 34)
            Spacer(); Spacer()
        }
    }

    private var howTo: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()
            Text("How to play").font(Theme.rounded(28)).foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .center)
            rule(color: Theme.correct, letter: "W", text: "Green — right letter, right spot.")
            rule(color: Theme.present, letter: "O", text: "Yellow — in the word, wrong spot.")
            rule(color: Theme.absent, letter: "X", text: "Gray — not in the word at all.")
            Spacer(); Spacer()
        }
        .padding(.horizontal, 30)
    }

    private func rule(color: Color, letter: String, text: String) -> some View {
        HStack(spacing: 14) {
            Text(letter).font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(RoundedRectangle(cornerRadius: 8).fill(color))
            Text(text).font(.system(size: 16)).foregroundStyle(Theme.ink)
        }
    }
}
