import SwiftUI

/// Three-page first-run onboarding gated by `AppSettings.hasOnboarded`.
struct OnboardingView: View {
    @Bindable var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var ownerName = ""

    private let pages: [OnboardingPage] = [
        OnboardingPage(symbol: "pawprint.fill", tint: Theme.accent,
                       title: "Welcome to Petal",
                       message: "Keep every pet's health in one calm, private place — no accounts, no ads."),
        OnboardingPage(symbol: "syringe.fill", tint: Theme.amber,
                       title: "Never miss care",
                       message: "Track medications, vaccinations, vet visits and feedings with one upcoming-care timeline."),
        OnboardingPage(symbol: "chart.xyaxis.line", tint: Theme.lilac,
                       title: "Watch them thrive",
                       message: "Log weights and see clear trends, so you spot changes early.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                    pageView(p, isLast: idx == pages.count - 1)
                        .tag(idx)
                        .padding(.horizontal, 28)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .easeInOut, value: page)

            pageDots
                .padding(.vertical, 18)

            controls
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
        }
        .petalScreenBackground()
    }

    private func pageView(_ p: OnboardingPage, isLast: Bool) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(p.tint.opacity(0.16)).frame(width: 150, height: 150)
                Image(systemName: p.symbol)
                    .font(.system(size: 62, weight: .semibold))
                    .foregroundStyle(p.tint)
            }
            .accessibilityHidden(true)

            Text(p.title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.primaryText)

            Text(p.message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            if isLast {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your name (optional)")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                    TextField("e.g. Sam", text: $ownerName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .accessibilityLabel("Your name")
                }
                .padding(.top, 8)
            }
            Spacer()
        }
        .accessibilityElement(children: .contain)
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.divider)
                    .frame(width: i == page ? 22 : 8, height: 8)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
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
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if page < pages.count - 1 {
                Button("Skip") { finish() }
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private func finish() {
        let trimmed = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.ownerName = trimmed
        settings.hasOnboarded = true
    }
}

private struct OnboardingPage {
    let symbol: String
    let tint: Color
    let title: String
    let message: String
}

#Preview {
    OnboardingView(settings: AppSettings())
        .modelContainer(PersistenceController.preview.container)
}
