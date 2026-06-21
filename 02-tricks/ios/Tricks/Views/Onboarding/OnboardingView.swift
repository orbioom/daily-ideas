import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Query private var settingsArr: [TricksSettings]
    @Environment(\.modelContext) private var ctx
    @State private var page = 0

    private var settings: TricksSettings {
        settingsArr.first ?? { let s = TricksSettings(); ctx.insert(s); return s }()
    }

    private let pages: [(String, String, String)] = [
        ("suit.spade.fill","Spades","The classic American trick-taking card game. Partner with the AI to beat East & West. Spades always trump!"),
        ("person.2.fill","Bid Smart","Each hand starts with bidding. Bid how many tricks you'll win. Hit your bid to score — miss it and lose points."),
        ("chart.bar.xaxis","First to 500","Race to 500 points. Watch your bags: too many overtricks and you lose 100 points!")
    ]

    var body: some View {
        ZStack {
            TricksTheme.background.ignoresSafeArea()
            VStack(spacing: 40) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                        VStack(spacing: 24) {
                            Image(systemName: p.0).font(.system(size: 72)).foregroundStyle(TricksTheme.accent).accessibilityHidden(true)
                            Text(p.1).font(.largeTitle.bold()).foregroundStyle(TricksTheme.primaryText).multilineTextAlignment(.center)
                            Text(p.2).font(.body).foregroundStyle(TricksTheme.secondaryText).multilineTextAlignment(.center).padding(.horizontal, 32)
                        }.tag(i)
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
                        .font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding()
                        .background(TricksTheme.accent, in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32).padding(.bottom, 48)
            }
        }
    }
}
