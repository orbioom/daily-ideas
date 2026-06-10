import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(icon: String, title: String, body: String)] = [
        ("square.grid.3x3", "Sudoku, done right",
         "Every board is generated on your device with a single guaranteed solution. Four difficulties, from a gentle start to a real challenge."),
        ("pencil.and.outline", "Pencil notes that keep up",
         "Drop candidate notes into any cell. Place a number and matching notes clear themselves automatically — no fiddly cleanup."),
        ("lightbulb", "Hints that teach",
         "Stuck? A hint finds a square you could have solved by logic and shows you which — so you learn the technique, not just the answer."),
        ("calendar", "A new puzzle every day",
         "Take on the daily challenge — the same board for everyone — and build a solving streak. No ads, no internet needed."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            ZStack {
                                Circle().fill(SudokuDifficulty.medium.tint.opacity(0.16)).frame(width: 120, height: 120)
                                Image(systemName: pages[i].icon)
                                    .font(.system(size: 46, weight: .light))
                                    .foregroundStyle(SudokuDifficulty.medium.tint)
                            }
                            .accessibilityHidden(true)
                            Text(pages[i].title).font(.title.bold())
                                .multilineTextAlignment(.center).foregroundStyle(Brand.text)
                            Text(pages[i].body).font(.body)
                                .multilineTextAlignment(.center).foregroundStyle(Brand.text2)
                                .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 32).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    Button(page < pages.count - 1 ? "Continue" : "Start playing") {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                        } else { Haptics.success(); onDone() }
                    }
                    .buttonStyle(InkButtonStyle())
                    if page < pages.count - 1 {
                        Button("Skip") { onDone() }.font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 28)
            }
        }
    }
}

#Preview { OnboardingView(onDone: {}) }
