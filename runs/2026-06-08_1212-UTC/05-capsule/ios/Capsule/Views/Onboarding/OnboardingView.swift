import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var includeSample = true
    @State private var sway = false

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("square.grid.2x2.fill", "Your whole wardrobe",
         "Capsule keeps every piece you own in one calm, fast catalog — no glitches, no 100-item paywall, no clutter."),
        ("hanger", "Build outfits you love",
         "Combine pieces into outfits, mark favorites, and plan what to wear on a calendar."),
        ("chart.bar.fill", "Wear what you have",
         "Track every wear to see cost-per-wear, your most-loved pieces, and what's been neglected. All on your device."),
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
                                    .font(.system(size: 52, weight: .light))
                                    .foregroundStyle(Color.accentColor)
                                    .rotationEffect(.degrees(i == 1 && sway && !reduceMotion ? 6 : -6))
                                    .accessibilityHidden(true)
                            }
                            VStack(spacing: 12) {
                                Text(pages[i].title).font(.title.weight(.bold))
                                    .foregroundStyle(Brand.text).multilineTextAlignment(.center)
                                Text(pages[i].body).font(.body).foregroundStyle(Brand.text2)
                                    .multilineTextAlignment(.center).padding(.horizontal, 32)
                            }
                        }.padding().tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 420)
                Spacer()
                VStack(spacing: 16) {
                    if page == pages.count - 1 {
                        Toggle(isOn: $includeSample) {
                            Text("Add a sample wardrobe to explore").font(.subheadline).foregroundStyle(Brand.text2)
                        }.tint(Color.accentColor)
                    }
                    Button(page == pages.count - 1 ? "Open my closet" : "Continue") {
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
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { sway = true }
        }
    }
}
