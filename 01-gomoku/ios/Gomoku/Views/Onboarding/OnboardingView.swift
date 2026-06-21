import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var prefs: [GomokuPrefs]
    @State private var page = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            TabView(selection: $page) {
                pageOne.tag(0)
                pageTwo.tag(1)
                pageThree.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }

    private var pageOne: some View {
        VStack(spacing: 24) {
            Spacer()
            Circle()
                .fill(Color(red: 0.1, green: 0.14, blue: 0.29))
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "circle.grid.3x3.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.white)
                }
            Text("Gomoku")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.white)
            Text("Five in a Row")
                .font(.title3)
                .foregroundStyle(.gray)
            Spacer()
            Button("Next") { withAnimation { page = 1 } }
                .buttonStyle(OnboardButtonStyle())
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 32)
    }

    private var pageTwo: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.accentColor)
            Text("How to Play")
                .font(.title.bold())
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 12) {
                ruleRow("Tap any intersection to place your stone.")
                ruleRow("Get 5 in a row — horizontal, vertical, or diagonal.")
                ruleRow("Block your opponent before they reach 5!")
            }
            .padding(.horizontal, 8)
            Spacer()
            Button("Next") { withAnimation { page = 2 } }
                .buttonStyle(OnboardButtonStyle())
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 32)
    }

    private var pageThree: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
            Text("Choose Your Side")
                .font(.title.bold())
                .foregroundStyle(.white)
            Text("Black always moves first. White is typically harder — choose what challenges you!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
            Spacer()
            Button("Start Playing") { finish() }
                .buttonStyle(OnboardButtonStyle())
            Spacer().frame(height: 40)
        }
        .padding(.horizontal, 32)
    }

    private func ruleRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
            Text(text)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func finish() {
        let p = prefs.first ?? GomokuPrefs()
        if prefs.isEmpty { ctx.insert(p) }
        p.onboardingDone = true
    }
}

struct OnboardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
