import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var includeSample = true
    @State private var spin = false

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("timer", "One tap to track",
         "Start the timer, do the work, stop. Stint keeps a clean record of where your hours go — no account, no cloud."),
        ("dollarsign.circle.fill", "Know what you've earned",
         "Set rates per client or project and Stint totals your billable hours and earnings as you go."),
        ("chart.pie.fill", "Reports you can send",
         "Group time by client and project for any week or month, then copy an invoice-ready summary. All yours, all on device."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 24) {
                            ZStack {
                                Circle().fill(.ultraThinMaterial).frame(width: 150, height: 150)
                                    .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                                Image(systemName: pages[i].symbol)
                                    .font(.system(size: 54, weight: .light))
                                    .foregroundStyle(Color.accentColor)
                                    .rotationEffect(.degrees(i == 0 && spin && !reduceMotion ? 360 : 0))
                                    .accessibilityHidden(true)
                            }
                            VStack(spacing: 12) {
                                Text(pages[i].title).font(.title.weight(.bold))
                                    .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                                Text(pages[i].body).font(.body).foregroundStyle(Brand.text2)
                                    .multilineTextAlignment(.center).padding(.horizontal, 32)
                            }
                        }
                        .padding().tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 420)
                Spacer()
                VStack(spacing: 16) {
                    if page == pages.count - 1 {
                        Toggle(isOn: $includeSample) {
                            Text("Load example clients & time").font(.subheadline).foregroundStyle(Brand.text2)
                        }.tint(Color.accentColor)
                    }
                    Button(page == pages.count - 1 ? "Start tracking" : "Continue") {
                        Haptics.tap()
                        if page < pages.count - 1 {
                            withAnimation(Brand.ease()) { page += 1 }
                        } else {
                            if includeSample { SeedData.populate(context) }
                            withAnimation(Brand.ease()) { hasOnboarded = true }
                        }
                    }.buttonStyle(InkButtonStyle())
                }
                .padding(.horizontal, 24).padding(.bottom, 32)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { spin = true }
        }
    }
}
