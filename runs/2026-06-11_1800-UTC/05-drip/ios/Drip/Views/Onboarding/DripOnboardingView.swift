import SwiftUI

struct DripOnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = [
        ("drop.fill", "Drink Mindfully", "Track your drinks, set a weekly limit, and see how you're trending — no judgment, just awareness."),
        ("chart.bar.fill", "Know Your Patterns", "See which contexts lead to more drinking, track alcohol-free days, and watch money savings grow."),
        ("target", "Set Your Goal", "Choose a weekly limit that works for you. Drip is here to support, not to lecture.")
    ]

    var body: some View {
        ZStack {
            DripTheme.bg.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        let p = pages[i]
                        VStack(spacing: 32) {
                            Spacer()
                            Image(systemName: p.0).font(.system(size: 80)).foregroundStyle(DripTheme.teal)
                                .accessibilityHidden(true)
                            VStack(spacing: 12) {
                                Text(p.1).font(.title2.weight(.bold)).foregroundStyle(DripTheme.text).multilineTextAlignment(.center)
                                Text(p.2).font(.body).foregroundStyle(DripTheme.subtle).multilineTextAlignment(.center).padding(.horizontal, 32)
                            }
                            Spacer()
                        }.tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                VStack(spacing: 20) {
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            Capsule().fill(i == page ? DripTheme.teal : DripTheme.subtle.opacity(0.3))
                                .frame(width: i == page ? 24 : 8, height: 8)
                                .animation(reduceMotion ? .none : .spring(response: 0.3), value: page)
                        }
                    }
                    Button(page < pages.count - 1 ? "Next" : "Let's Get Started") {
                        if page < pages.count - 1 { withAnimation(reduceMotion ? .none : .easeInOut) { page += 1 } }
                        else { isComplete = true }
                    }
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(DripTheme.teal).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }
}
