import SwiftUI
import SwiftData

/// Intro onboarding ending in "add your first child", gated by hasOnboarded.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var showAddChild = false

    private struct Page: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let pages: [Page] = [
        Page(symbol: "chart.xyaxis.line",
             title: "Percentiles done right",
             body: "Plot weight, height, and head circumference on real WHO growth curves — and read each one in plain language. No clutter, no daily logging."),
        Page(symbol: "checklist",
             title: "Milestones & vaccines",
             body: "Follow developmental milestones by age and a clear immunization schedule. See what's on track, what's coming up, and what's overdue at a glance."),
        Page(symbol: "lock.shield",
             title: "Private and on-device",
             body: "Everything stays on your iPhone — nothing is uploaded. Sprig is informational and never a substitute for your pediatrician's advice.")
    ]

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        pageView(item).tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    PrimaryButton(title: page == pages.count - 1 ? "Add your first child" : "Next",
                                  systemImage: page == pages.count - 1 ? "plus" : "arrow.right") {
                        advance()
                    }
                    Button("Skip for now") { finishWithoutChild() }
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(page == pages.count - 1 ? 0 : 1)
                        .disabled(page == pages.count - 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showAddChild) {
            AddChildView(isFirstChild: true) { _ in
                hasOnboarded = true
            }
        }
    }

    private func pageView(_ item: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 76, weight: .regular))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(item.title)
                .font(Theme.rounded(30, .bold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text(item.body)
                .font(Theme.rounded(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Spacer()
        }
        .padding(.bottom, 40)
    }

    private func advance() {
        if page < pages.count - 1 {
            Haptics.select(settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            showAddChild = true
        }
    }

    private func finishWithoutChild() {
        Haptics.select(settings.hapticsEnabled)
        hasOnboarded = true
    }
}
