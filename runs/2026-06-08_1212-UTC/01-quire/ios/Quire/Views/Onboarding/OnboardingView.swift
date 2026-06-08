import SwiftUI
import SwiftData

struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var includeSamples = true
    @State private var breathe = false

    private let pages: [(symbol: String, title: String, body: String)] = [
        ("book.closed.fill", "A place to think",
         "Quire is a calm, private journal. Write freely, or follow a gentle prompt — whatever the day asks for."),
        ("sparkles", "Prompts when you're stuck",
         "A fresh prompt arrives each day, with a deck you can browse anytime across reflection, gratitude, and growth."),
        ("lock.fill", "Yours alone",
         "Everything stays on your device. No account, no cloud, no ads. Your words don't leave your pocket."),
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
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 150, height: 150)
                                    .overlay(Circle().strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1))
                                    .scaleEffect(breathe && !reduceMotion ? 1.05 : 1)
                                Image(systemName: pages[i].symbol)
                                    .font(.system(size: 56, weight: .light))
                                    .foregroundStyle(Color.accentColor)
                                    .accessibilityHidden(true)
                            }
                            VStack(spacing: 12) {
                                Text(pages[i].title)
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(Brand.text)
                                    .multilineTextAlignment(.center)
                                Text(pages[i].body)
                                    .font(.body)
                                    .foregroundStyle(Brand.text2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .padding()
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 420)

                Spacer()

                VStack(spacing: 16) {
                    if page == pages.count - 1 {
                        Toggle(isOn: $includeSamples) {
                            Text("Start with a few example entries")
                                .font(.subheadline)
                                .foregroundStyle(Brand.text2)
                        }
                        .tint(Color.accentColor)
                        .padding(.horizontal, 4)
                    }

                    Button(page == pages.count - 1 ? "Begin" : "Continue") {
                        Haptics.tap()
                        if page < pages.count - 1 {
                            withAnimation(Brand.ease()) { page += 1 }
                        } else {
                            if includeSamples { SeedData.populate(context) }
                            withAnimation(Brand.ease()) { hasOnboarded = true }
                        }
                    }
                    .buttonStyle(InkButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}
