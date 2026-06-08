import SwiftUI

struct OnboardingView: View {
    @Binding var done: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("flame.fill", "Burn, not bloat",
         "Ember tracks your fasting window with a live ring and the metabolic stages your body moves through — fed, ketosis, fat burning, autophagy."),
        ("timer", "One tap to start",
         "Pick a protocol like 16:8, start your fast, and Ember keeps counting even after you close the app. No accounts, all on your device."),
        ("chart.bar.fill", "See the streak build",
         "Every completed fast feeds your streak, completion rate, and weekly chart — so the habit becomes visible and sticky."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer()
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            Image(systemName: pages[i].symbol)
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(Brand.inkGradient)
                                .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(Brand.text)
                                .multilineTextAlignment(.center)
                            Text(pages[i].body)
                                .font(.body)
                                .foregroundStyle(Brand.text2)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }
                        .tag(i)
                        .padding()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 360)

                Spacer()

                Button(page == pages.count - 1 ? "Start fasting" : "Continue") {
                    if page == pages.count - 1 {
                        Haptics.success()
                        withAnimation(reduceMotion ? nil : Brand.ease()) { done = true }
                    } else {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    }
                }
                .buttonStyle(InkButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
}
