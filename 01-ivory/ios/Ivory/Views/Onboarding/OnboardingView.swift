import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var settingsArr: [IvorySettings]
    @Environment(\.modelContext) private var ctx
    @State private var page = 0

    private var settings: IvorySettings {
        settingsArr.first ?? { let s = IvorySettings(); ctx.insert(s); return s }()
    }

    private let pages: [(String, String, String)] = [
        ("circle.grid.2x2","Reversi / Othello","Flip your opponent's discs to control the board. Corners are king — guard them fiercely."),
        ("cpu","Smart AI Opponent","Three difficulty levels. Beginner to hone your instincts. Advanced to test your limits."),
        ("chart.bar.xaxis","Track Your Progress","Every game saved. See your win rate, averages, and best performances over time.")
    ]

    var body: some View {
        ZStack {
            IvoryTheme.background.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                        VStack(spacing: 24) {
                            Image(systemName: p.0)
                                .font(.system(size: 72))
                                .foregroundStyle(IvoryTheme.accent)
                                .accessibilityHidden(true)
                            Text(p.1)
                                .font(.largeTitle.bold())
                                .foregroundStyle(IvoryTheme.primaryText)
                                .multilineTextAlignment(.center)
                            Text(p.2)
                                .font(.body)
                                .foregroundStyle(IvoryTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 380)
                Spacer()
                Button {
                    if page < pages.count - 1 { withAnimation { page += 1 } }
                    else { settings.hasCompletedOnboarding = true }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Start Playing")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(IvoryTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .accessibilityLabel(page < pages.count - 1 ? "Continue to next screen" : "Start playing Ivory")
            }
        }
    }
}
