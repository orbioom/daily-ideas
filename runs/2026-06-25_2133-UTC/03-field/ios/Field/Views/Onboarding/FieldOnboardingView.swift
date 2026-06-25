import SwiftUI
import SwiftData

struct FieldOnboardingView: View {
    @Query private var allSettings: [FieldSettings]
    @Environment(\.modelContext) private var context
    @State private var page = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [FieldTheme.fern, Color(red: 0.118, green: 0.247, blue: 0.141)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ObPage(
                        sfSymbol: "leaf.fill",
                        title: "Your Nature Journal",
                        body: "Log every sighting — birds, mammals, plants, fungi, insects, reptiles, and more — with conditions, behavior, and notes.",
                        tag: 0
                    )
                    ObPage(
                        sfSymbol: "star.fill",
                        title: "Track Your Lifers",
                        body: "Mark first-ever sightings as Lifers. Build your life list across all species — not just birds.",
                        tag: 1
                    )
                    ObPage(
                        sfSymbol: "chart.bar.fill",
                        title: "Explore Your Data",
                        body: "See which habitats you visit most, your most-observed classes, observation trends, and your top locations.",
                        tag: 2
                    )
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == page ? Color.white : Color.white.opacity(0.35))
                            .frame(width: i == page ? 10 : 7, height: i == page ? 10 : 7)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                .padding(.bottom, 24)

                Button(action: advance) {
                    Text(page == 2 ? "Start Observing" : "Next")
                        .font(.headline)
                        .foregroundStyle(FieldTheme.fern)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func advance() {
        if page < 2 { withAnimation { page += 1 } }
        else {
            allSettings.first?.showOnboarding = false
            try? context.save()
        }
    }
}

private struct ObPage: View {
    let sfSymbol: String
    let title: String
    let body: String
    let tag: Int

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: sfSymbol)
                .font(.system(size: 80, weight: .thin))
                .foregroundStyle(.white)
                .accessibilityHidden(true)
            VStack(spacing: 14) {
                Text(title).font(.title.bold()).foregroundStyle(.white)
                Text(body).font(.body).foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center).padding(.horizontal, 12)
            }
            Spacer()
        }
        .tag(tag)
        .padding(.horizontal, 24)
    }
}
