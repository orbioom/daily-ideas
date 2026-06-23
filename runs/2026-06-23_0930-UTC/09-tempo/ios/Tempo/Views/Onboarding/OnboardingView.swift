import SwiftUI
import SwiftData

/// First-run onboarding. Lets the user pick a preferred unit, gated by a persisted
/// flag (`hasOnboarded`) so it only appears once.
struct OnboardingView: View {
    @Binding var hasOnboarded: Bool
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var settings: [AppSettings]

    @State private var page = 0
    @State private var unit: WeightUnit = .kg

    private let pages: [OnboardPage] = [
        OnboardPage(symbol: "bolt.fill", tint: Theme.accent,
                    title: "Log sets at lightning speed",
                    body: "Tap a lift, punch in weight × reps, done. Tempo keeps the friction out of every set."),
        OnboardPage(symbol: "trophy.fill", tint: Theme.pr,
                    title: "Catch every PR automatically",
                    body: "Tempo estimates your 1RM with the Epley formula and flags top-weight, volume, and 1RM records the moment you hit them."),
        OnboardPage(symbol: "timer", tint: Theme.rest,
                    title: "Rest timer & plate math built in",
                    body: "A calm rest timer counts down between sets, and the plate calculator tells you exactly what to load on the bar."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        pageView(p).tag(idx)
                    }
                    unitPage.tag(pages.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                pageDots
                    .padding(.bottom, 8)

                controls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    private func pageView(_ p: OnboardPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(p.tint.opacity(0.16))
                    .frame(width: 168, height: 168)
                Image(systemName: p.symbol)
                    .font(.system(size: 68, weight: .semibold))
                    .foregroundStyle(p.tint)
            }
            .accessibilityHidden(true)
            VStack(spacing: 12) {
                Text(p.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)
                Text(p.body)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var unitPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "scalemass.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Pick your unit")
                .font(.title.bold())
                .foregroundStyle(Theme.textPrimary)
            Text("You can change this anytime in Settings.")
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
            Picker("Weight unit", selection: $unit) {
                ForEach(WeightUnit.allCases) { u in
                    Text(u.display.uppercased()).tag(u)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 48)
            Spacer()
            Spacer()
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0...pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Theme.accent : Theme.cardStroke)
                    .frame(width: i == page ? 22 : 8, height: 8)
                    .animation(reduceMotion ? nil : .spring(duration: 0.3), value: page)
            }
        }
        .accessibilityHidden(true)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            PrimaryButton(title: page < pages.count ? "Continue" : "Start Training",
                          systemImage: page < pages.count ? "arrow.right" : "checkmark") {
                if page < pages.count {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
                } else {
                    finish()
                }
            }
            if page < pages.count {
                Button("Skip") {
                    withAnimation(reduceMotion ? nil : .easeInOut) { page = pages.count }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func finish() {
        if let s = settings.first {
            s.unit = unit
            try? context.save()
        }
        withAnimation(reduceMotion ? nil : .easeInOut) {
            hasOnboarded = true
        }
    }
}

private struct OnboardPage {
    let symbol: String
    let tint: Color
    let title: String
    let body: String
}

#Preview {
    OnboardingView(hasOnboarded: .constant(false))
        .modelContainer(PersistenceController.preview)
}
