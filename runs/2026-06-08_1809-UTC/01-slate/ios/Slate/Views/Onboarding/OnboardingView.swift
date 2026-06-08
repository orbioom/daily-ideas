import SwiftUI

struct OnboardingView: View {
    @AppStorage("slate.onboarded") private var onboarded = false
    @State private var page = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let body: String
    }

    private let pages = [
        Page(icon: "calendar.day.timeline.left",
             title: "See your day, not a list",
             body: "Slate lays your plans on a real timeline so you feel the shape of your day at a glance."),
        Page(icon: "square.stack.3d.up",
             title: "Routines in one tap",
             body: "Save the blocks you schedule again and again, then drop them onto any day instantly."),
        Page(icon: "chart.pie",
             title: "Know where it goes",
             body: "Completion, free time, and time-by-category — calm insights that respect your attention."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { idx, p in
                    VStack(spacing: 22) {
                        Spacer()
                        Image(systemName: p.icon)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(Color(hex: 0x5E63A6))
                            .accessibilityHidden(true)
                        Text(p.title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Brand.text)
                            .multilineTextAlignment(.center)
                        Text(p.body)
                            .font(.body)
                            .foregroundStyle(Brand.text2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 36)
                        Spacer()
                    }
                    .tag(idx)
                    .padding()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)

            VStack(spacing: 12) {
                Button(page == pages.count - 1 ? "Get started" : "Continue") {
                    if page == pages.count - 1 {
                        Haptics.success()
                        onboarded = true
                    } else {
                        withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                    }
                }
                .buttonStyle(InkButtonStyle())

                if page < pages.count - 1 {
                    Button("Skip") { onboarded = true }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text2)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 28)
        }
    }
}
