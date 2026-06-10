import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var glow = false

    private let pages: [(icon: String, title: String, body: String)] = [
        ("square.grid.3x3.fill", "Sudoku, done right",
         "Clean, fast, and ad-free. Endless puzzles in four difficulties, generated fresh on your device every time."),
        ("pencil.tip", "Notes that help, not nag",
         "Pencil in candidates, highlight matching numbers, and let optional conflict checks catch slips — all toggleable."),
        ("calendar.badge.clock", "A new puzzle every day",
         "Build a daily streak with one challenge a day, and watch your best times drop in the stats.")
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 28) {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 24).fill(Brand.info.opacity(0.15))
                        .frame(width: 176, height: 176)
                        .scaleEffect(glow && !reduceMotion ? 1.04 : 0.94)
                    Image(systemName: pages[page].icon)
                        .font(.system(size: 56, weight: .light)).foregroundStyle(Brand.text)
                }
                .accessibilityHidden(true)
                VStack(spacing: 12) {
                    Text(pages[page].title).font(.title.weight(.bold)).foregroundStyle(Brand.text)
                        .multilineTextAlignment(.center)
                    Text(pages[page].body).font(.body).foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule().fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                            .frame(width: i == page ? 22 : 8, height: 8)
                    }
                }
                .accessibilityHidden(true)
                Button(page == pages.count - 1 ? "Play" : "Continue") {
                    Haptics.tap()
                    if page == pages.count - 1 { hasOnboarded = true }
                    else { withAnimation(Brand.ease()) { page += 1 } }
                }
                .buttonStyle(InkButtonStyle()).padding(.horizontal, 28)
                if page < pages.count - 1 {
                    Button("Skip") { hasOnboarded = true }
                        .font(.subheadline).foregroundStyle(Brand.text3)
                }
            }
            .padding(.bottom, 28)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { glow = true }
        }
    }
}
