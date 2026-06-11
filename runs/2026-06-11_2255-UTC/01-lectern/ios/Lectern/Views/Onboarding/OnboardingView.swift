import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var page = 0

    private let pages: [(icon: String, title: String, message: String)] = [
        ("text.viewfinder", "Your pocket teleprompter",
         "Write or paste a script, hit play, and read at a perfectly steady pace — for videos, speeches, lectures and auditions."),
        ("speedometer", "Total control while you read",
         "Adjust speed and text size live, drag to seek, mirror the display for beam-splitter glass, and keep your eyes on the guide line."),
        ("chart.bar.xaxis", "Rehearse until it lands",
         "Every run-through is logged with its pace and duration, so you can watch your delivery tighten over time."),
    ]

    var body: some View {
        ZStack {
            Theme.stage.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 22) {
                            Image(systemName: item.icon)
                                .font(.system(size: 64, weight: .light))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            Text(item.title)
                                .font(.system(.largeTitle, design: .serif, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            Text(item.message)
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                        .padding(.bottom, 60)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        Haptics.success()
                        hasOnboarded = true
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Start writing")
                        .font(.headline)
                        .foregroundStyle(Theme.stage)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .accessibilityHint(page < pages.count - 1 ? "Shows the next page" : "Finishes onboarding")
            }
        }
        .preferredColorScheme(.dark)
    }
}
