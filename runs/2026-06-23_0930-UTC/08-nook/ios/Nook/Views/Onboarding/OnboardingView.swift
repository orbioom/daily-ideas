import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var hasOnboarded: Bool
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    private let pages: [OnboardPage] = [
        .init(systemImage: "house.fill",
              title: "Welcome to Nook",
              body: "Your home's upkeep, organised. Nook keeps every recurring maintenance task on schedule so nothing slips."),
        .init(systemImage: "clock.badge.checkmark",
              title: "Know what's due",
              body: "Filters, HVAC service, smoke-detector batteries, gutters — Nook tracks each cadence and surfaces overdue and upcoming work first."),
        .init(systemImage: "wrench.and.screwdriver.fill",
              title: "Every appliance, on record",
              body: "Log models, purchase dates and warranties for your equipment. Attach tasks so service history lives with the appliance."),
        .init(systemImage: "checkmark.seal.fill",
              title: "One tap to stay ahead",
              body: "Mark a task done and Nook rolls it forward to its next due date automatically. A starter checklist is ready for you.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, p in
                    OnboardPageView(page: p)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .animation(reduceMotion ? nil : .easeInOut, value: page)

            VStack(spacing: Theme.Spacing.md) {
                Button {
                    if page < pages.count - 1 {
                        withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                    } else {
                        finish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Continue" : "Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .accessibilityHint(page < pages.count - 1 ? "Goes to the next page" : "Finishes setup and seeds your home")

                if page < pages.count - 1 {
                    Button("Skip") { finish() }
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.bg.ignoresSafeArea())
    }

    private func finish() {
        // Seeding the starter home is idempotent.
        SeedData.seedIfNeeded(context: context)
        let haptics = SettingsStore.current(in: context).hapticsEnabled
        Haptics.success(enabled: haptics)
        withAnimation(reduceMotion ? nil : .easeInOut) {
            hasOnboarded = true
        }
    }
}

struct OnboardPage {
    let systemImage: String
    let title: String
    let body: String
}

struct OnboardPageView: View {
    let page: OnboardPage
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.12))
                    .frame(width: 160, height: 160)
                Image(systemName: page.systemImage)
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(Theme.accent)
            }
            .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.md) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)
                Text(page.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, Theme.Spacing.xl)
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(page.title). \(page.body)")
    }
}

#Preview {
    OnboardingView(hasOnboarded: .constant(false))
        .previewModelContainer()
}
