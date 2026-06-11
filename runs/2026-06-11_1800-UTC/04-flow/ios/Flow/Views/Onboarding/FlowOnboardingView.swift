import SwiftUI

struct FlowOnboardingView: View {
    @Binding var isComplete: Bool
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = [
        ("figure.yoga", "Yoga, Your Way", "8 guided sessions from quick morning flows to deep evening stretches — no subscription, no ads."),
        ("play.circle.fill", "Guided Step by Step", "Flow guides you through every pose with breathing cues, timers, and gentle transitions."),
        ("chart.bar.fill", "Track Your Progress", "Log mood before and after, build your practice streak, and watch your flexibility grow.")
    ]

    var body: some View {
        ZStack {
            FlowTheme.bg.ignoresSafeArea()
            VStack {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        let p = pages[i]
                        VStack(spacing: 32) {
                            Spacer()
                            Image(systemName: p.0).font(.system(size: 80)).foregroundStyle(FlowTheme.sage)
                                .accessibilityHidden(true)
                            VStack(spacing: 12) {
                                Text(p.1).font(.title2.weight(.bold)).foregroundStyle(FlowTheme.text).multilineTextAlignment(.center)
                                Text(p.2).font(.body).foregroundStyle(FlowTheme.subtle).multilineTextAlignment(.center).padding(.horizontal, 32)
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
                            Capsule().fill(i == page ? FlowTheme.sage : FlowTheme.subtle.opacity(0.3))
                                .frame(width: i == page ? 24 : 8, height: 8)
                                .animation(reduceMotion ? .none : .spring(response: 0.3), value: page)
                        }
                    }
                    Button(page < pages.count - 1 ? "Next" : "Begin Your Practice") {
                        if page < pages.count - 1 { withAnimation(reduceMotion ? .none : .easeInOut) { page += 1 } }
                        else { isComplete = true }
                    }
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(FlowTheme.sage).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16)).padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }
}
