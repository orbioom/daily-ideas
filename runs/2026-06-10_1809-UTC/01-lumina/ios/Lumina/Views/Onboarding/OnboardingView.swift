import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages: [(icon: String, title: String, body: String)] = [
        ("sun.max", "A calmer kind of affirmation app",
         "Lumina is quiet by design. No ads, no feed of other apps, no nagging — just words worth returning to."),
        ("square.stack", "A library that never repeats itself",
         "Over a hundred affirmations across eight themes, plus your own. Browse, favorite, and shape your own collection."),
        ("play.circle", "A breathing practice, not a wall of text",
         "Settle into a gentle full-screen session: each affirmation rises with your breath, at your pace."),
        ("lock", "Yours, and only yours",
         "Everything lives on this device. No account, no cloud, no tracking. Your reflections stay private."),
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
                                Circle()
                                    .fill(Brand.magic.opacity(0.16))
                                    .frame(width: 120, height: 120)
                                Image(systemName: pages[i].icon)
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundStyle(Brand.magic)
                            }
                            .accessibilityHidden(true)
                            Text(pages[i].title)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Brand.text)
                            Text(pages[i].body)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Brand.text2)
                                .padding(.horizontal, 8)
                        }
                        .padding(.horizontal, 32)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    Button(page < pages.count - 1 ? "Continue" : "Begin") {
                        if page < pages.count - 1 {
                            withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                        } else {
                            Haptics.success()
                            onDone()
                        }
                    }
                    .buttonStyle(InkButtonStyle())

                    if page < pages.count - 1 {
                        Button("Skip") { onDone() }
                            .font(.subheadline)
                            .foregroundStyle(Brand.text2)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
    }
}

#Preview {
    OnboardingView(onDone: {})
}
