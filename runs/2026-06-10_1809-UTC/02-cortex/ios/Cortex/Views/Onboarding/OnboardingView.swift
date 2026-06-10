import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(icon: String, title: String, body: String)] = [
        ("bolt", "Five games, five minds",
         "Numeracy, attention, reasoning, memory, and language — each a quick, focused game built to challenge a different part of your thinking."),
        ("infinity", "No daily cap, ever",
         "Other trainers lock you out after three games. Cortex is free to play as much as you like, with content that's generated fresh so it never repeats."),
        ("calendar", "A workout that adapts to the day",
         "Each day picks three games for a short combined workout. Build a streak, beat your bests, and watch your trend climb."),
        ("lock", "Private and honest",
         "No ads, no account, no year-two price hike. Your scores live on this device and nowhere else."),
    ]

    var body: some View {
        ZStack {
            Brand.pageBackground
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 22) {
                            ZStack {
                                Circle().fill(Brand.info.opacity(0.16)).frame(width: 120, height: 120)
                                Image(systemName: pages[i].icon)
                                    .font(.system(size: 48, weight: .light)).foregroundStyle(Brand.info)
                            }
                            .accessibilityHidden(true)
                            Text(pages[i].title).font(.title.bold())
                                .multilineTextAlignment(.center).foregroundStyle(Brand.text)
                            Text(pages[i].body).font(.body)
                                .multilineTextAlignment(.center).foregroundStyle(Brand.text2)
                                .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 32).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                Spacer(minLength: 0)
                VStack(spacing: 12) {
                    Button(page < pages.count - 1 ? "Continue" : "Start training") {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                        } else { Haptics.success(); onDone() }
                    }
                    .buttonStyle(InkButtonStyle())
                    if page < pages.count - 1 {
                        Button("Skip") { onDone() }.font(.subheadline).foregroundStyle(Brand.text2)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 28)
            }
        }
    }
}

#Preview { OnboardingView(onDone: {}) }
