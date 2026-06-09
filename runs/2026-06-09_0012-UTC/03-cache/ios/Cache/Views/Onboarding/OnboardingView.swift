import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("cache.onboarded") private var onboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("target", "Save for what matters",
         "Cache turns vague intentions into clear goals — a trip, a fund, a big purchase — each with its own progress."),
        ("chart.line.uptrend.xyaxis", "Know exactly when you'll get there",
         "Log deposits and Cache projects your finish date from your real pace, or the monthly plan you set."),
        ("lock.shield.fill", "Yours alone",
         "No bank logins, no ads, no accounts. Everything stays private on your device.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { i in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: pages[i].icon)
                            .font(.system(size: 70, weight: .light))
                            .foregroundStyle(Brand.magic)
                            .accessibilityHidden(true)
                        Text(pages[i].title).font(.title.weight(.bold))
                            .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                        Text(pages[i].body).font(.body)
                            .foregroundStyle(Brand.text2).multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                        Spacer()
                    }
                    .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 12) {
                Button(page == pages.count - 1 ? "Start saving" : "Continue") {
                    if page == pages.count - 1 { Haptics.success(); onboarded = true }
                    else { withAnimation(Brand.ease()) { page += 1 } }
                }
                .buttonStyle(InkButtonStyle())

                if page == pages.count - 1 {
                    Button("Explore with sample goals") {
                        SeedData.loadSample(context); Haptics.success(); onboarded = true
                    }
                    .buttonStyle(GlassButtonStyle())
                }

                HStack(spacing: 7) {
                    ForEach(pages.indices, id: \.self) { i in
                        Circle().fill(i == page ? Brand.text : Brand.text3.opacity(0.4))
                            .frame(width: 7, height: 7)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .padding(24)
    }
}
