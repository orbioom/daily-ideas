import SwiftUI

/// First-run onboarding: explain the idea, then let the user choose which starter trackers to
/// activate. The picks are stashed in @AppStorage and consumed by RootView's seeder. Gated by
/// `hasOnboarded`.
struct OnboardingView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @AppStorage("onboardingPicks") private var onboardingPicksRaw = ""
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var page = 0
    @State private var picks: Set<String> = Set(SeedData.starterNames)

    private struct Intro: Identifiable {
        let id = UUID()
        let symbol: String
        let title: String
        let body: String
    }

    private let intros: [Intro] = [
        Intro(symbol: "square.and.pencil",
              title: "Track anything, in seconds",
              body: "Log symptoms, mood, sleep, meds, food, weather — whatever matters to you. A slider, a tap, a number. No friction, no judgement."),
        Intro(symbol: "sparkles",
              title: "See what actually moves you",
              body: "Inkling ranks the real correlations in your data — \u{201C}caffeine → headache, strong\u{201D} — so you stop guessing and start noticing."),
        Intro(symbol: "lock.open",
              title: "Free, private, unlimited",
              body: "Correlations and your full history are free, forever, and stay on this device. No 30-day wall, no upload.")
    ]

    private var pageCount: Int { intros.count + 1 }   // +1 for the picker page

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(intros.enumerated()), id: \.element.id) { index, item in
                        introPage(item).tag(index)
                    }
                    pickerPage.tag(intros.count)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(reduceMotion ? nil : .easeInOut, value: page)

                VStack(spacing: 12) {
                    PrimaryButton(title: page == pageCount - 1 ? "Start tracking" : "Next",
                                  systemImage: page == pageCount - 1 ? "checkmark" : "arrow.right",
                                  enabled: page < pageCount - 1 || !picks.isEmpty) {
                        advance()
                    }
                    Button("Skip") { finish() }
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                        .opacity(page == pageCount - 1 ? 0 : 1)
                        .disabled(page == pageCount - 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func introPage(_ item: Intro) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: item.symbol)
                .font(.system(size: 74, weight: .regular))
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

    private var pickerPage: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Pick your starters")
                    .font(Theme.rounded(27, .bold))
                    .foregroundStyle(Theme.ink)
                Text("Turn on what you want to track now. You can add, edit, or remove anything later.")
                    .font(Theme.rounded(15))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 24)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(SeedData.starterNames, id: \.self) { name in
                        starterChip(name)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
    }

    private func starterChip(_ name: String) -> some View {
        let selected = picks.contains(name)
        return Button {
            Haptics.select(settings.hapticsEnabled)
            if selected { picks.remove(name) } else { picks.insert(name) }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Theme.accent : Theme.inkFaint)
                    .accessibilityHidden(true)
                Text(name)
                    .font(Theme.rounded(16, .medium))
                    .foregroundStyle(Theme.ink)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .fill(selected ? Theme.accentSoft : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                    .strokeBorder(selected ? Theme.accent.opacity(0.4) : Theme.hairline, lineWidth: 1)
            )
        }
        .accessibilityLabel(name)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityHint("Double-tap to toggle this starter tracker")
    }

    private func advance() {
        if page < pageCount - 1 {
            Haptics.select(settings.hapticsEnabled)
            withAnimation(reduceMotion ? nil : .easeInOut) { page += 1 }
        } else {
            finish()
        }
    }

    private func finish() {
        let chosen = picks.isEmpty ? SeedData.starterNames : Array(picks)
        onboardingPicksRaw = chosen.joined(separator: "|")
        Haptics.success(settings.hapticsEnabled)
        hasOnboarded = true
    }
}
