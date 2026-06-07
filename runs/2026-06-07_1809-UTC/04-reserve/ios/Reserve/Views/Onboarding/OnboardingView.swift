import SwiftUI

/// A short, paged welcome. On finish it calls `onFinish`, which seeds sample
/// data and flips the onboarding flag in `RootView`.
struct OnboardingView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages = OnboardingPage.all

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                    OnboardingPanel(page: item)
                        .tag(index)
                        .padding(.horizontal, 28)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : Brand.ease(), value: page)

            PageDots(count: pages.count, index: page)
                .padding(.bottom, 24)

            controls
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            Button(isLast ? "Get started" : "Continue") {
                Haptics.tap()
                if isLast {
                    Haptics.success()
                    onFinish()
                } else {
                    withAnimation(reduceMotion ? nil : Brand.ease()) { page += 1 }
                }
            }
            .buttonStyle(InkButtonStyle())

            if !isLast {
                Button("Skip") {
                    Haptics.tap()
                    onFinish()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Brand.text3)
                .font(.subheadline.weight(.medium))
            }
        }
    }

    private var isLast: Bool { page >= pages.count - 1 }
}

private struct OnboardingPanel: View {
    let page: OnboardingPage
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            Image(systemName: page.icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(page.tint)
                .frame(height: 96)
                .accessibilityHidden(true)
            VStack(spacing: 12) {
                Eyebrow(text: page.eyebrow)
                Text(page.title)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Brand.text)
                    .multilineTextAlignment(.center)
                Text(page.body)
                    .font(.body)
                    .foregroundStyle(Brand.text2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.body)")
    }
}

private struct PageDots: View {
    let count: Int
    let index: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Brand.text : Brand.text3.opacity(0.4))
                    .frame(width: i == index ? 22 : 8, height: 8)
                    .animation(Brand.ease(0.3), value: index)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let eyebrow: String
    let title: String
    let body: String
    let icon: String
    let tint: Color

    static let all: [OnboardingPage] = [
        OnboardingPage(
            eyebrow: "Reserve",
            title: "Plan your power",
            body: "An off-grid energy budget for vanlife, RVs, boats and cabins — sized to your real gear.",
            icon: "bolt.batteryblock",
            tint: Brand.magic
        ),
        OnboardingPage(
            eyebrow: "Loads",
            title: "List what you run",
            body: "Add appliances by watts, hours per day and quantity. Reserve totals your daily watt-hours and amp-hours.",
            icon: "list.bullet.rectangle",
            tint: Brand.info
        ),
        OnboardingPage(
            eyebrow: "Balance",
            title: "Solar vs. draw",
            body: "See days of autonomy without sun, daily solar harvest, net surplus or deficit, and recharge time.",
            icon: "sun.max",
            tint: Brand.warn
        ),
        OnboardingPage(
            eyebrow: "Size it",
            title: "Right-size the build",
            body: "Tell Reserve how many cloudy days you want to ride out — it recommends battery and solar to match.",
            icon: "slider.horizontal.3",
            tint: Brand.live
        )
    ]
}

#Preview {
    OnboardingView { }
        .background(Brand.pageBackground)
}
