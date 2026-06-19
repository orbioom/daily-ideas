import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [AppPreferences]
    @State private var page = 0

    var body: some View {
        ZStack {
            Color("FeltGreen").ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    page0.tag(0)
                    page1.tag(1)
                    page2.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i == page ? ApexTheme.gold : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.spring(), value: page)
                    }
                }
                .padding(.top, 12)

                Button(page < 2 ? "Next" : "Deal Me In") {
                    if page < 2 { withAnimation { page += 1 } } else { finish() }
                }
                .apexButtonStyle(color: ApexTheme.gold)
                .padding(.top, 20)
                .padding(.bottom, 40)
                .padding(.horizontal, 40)
            }
        }
    }

    private var page0: some View {
        VStack(spacing: 20) {
            Text("♠ APEX ♥")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .foregroundStyle(ApexTheme.gold)
            Text("Pyramid Solitaire")
                .font(.apexTitle())
                .foregroundStyle(.white)
            Text("Clear the entire pyramid by pairing cards that add up to 13. Kings can be removed alone.")
                .font(.apexBody())
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var page1: some View {
        VStack(spacing: 20) {
            Text("♦ HOW IT WORKS ♣")
                .font(.apexBody().bold())
                .foregroundStyle(ApexTheme.gold)
            VStack(alignment: .leading, spacing: 12) {
                ruleRow("A pair summing to 13", detail: "A+Q, 2+J, 3+10, 4+9, 5+8, 6+7")
                ruleRow("Kings alone", detail: "K removes by itself for 50 points!")
                ruleRow("Only uncovered cards", detail: "Cards are uncovered once the row below them is cleared")
                ruleRow("Draw pile", detail: "Tap to reveal extra cards. 3 passes allowed")
            }
            .padding(.horizontal, 28)
        }
    }

    private var page2: some View {
        VStack(spacing: 20) {
            Text("♣ SCORING ♠")
                .font(.apexBody().bold())
                .foregroundStyle(ApexTheme.gold)
            VStack(spacing: 12) {
                scoreRow("King removed alone", "50 pts")
                scoreRow("Ace or low pair", "30 pts")
                scoreRow("Other pairs", "20 pts")
                scoreRow("Clear the pyramid!", "+250 bonus")
            }
            .padding(.horizontal, 28)
            Text("No ads. No subscriptions.\nJust pure card game fun.")
                .font(.apexBody())
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private func ruleRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.apexBody().bold()).foregroundStyle(ApexTheme.gold)
            Text(detail).font(.apexCaption()).foregroundStyle(.white.opacity(0.7))
        }
    }

    private func scoreRow(_ label: String, _ pts: String) -> some View {
        HStack {
            Text(label).font(.apexBody()).foregroundStyle(.white.opacity(0.9))
            Spacer()
            Text(pts).font(.apexBody().bold()).foregroundStyle(ApexTheme.gold)
        }
    }

    private func finish() {
        if let p = prefs.first {
            p.hasSeenOnboarding = true
        } else {
            let p = AppPreferences()
            p.hasSeenOnboarding = true
            ctx.insert(p)
        }
    }
}
