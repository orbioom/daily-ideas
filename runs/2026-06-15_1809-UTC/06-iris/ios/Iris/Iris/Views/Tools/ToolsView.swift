import SwiftUI

struct ToolsView: View {
    @AppStorage("isPro") private var isPro = false
    @State private var paywallReason: PaywallReason?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    disclaimerBanner
                    toolLink(title: "Amsler grid", subtitle: "A simple self-check for distortions in your central vision.",
                             symbol: "grid", free: true) {
                        AnyView(AmslerGridView())
                    }
                    toolLink(title: "Focus flexibility", subtitle: "A near-to-far drill to limber up tired focusing muscles.",
                             symbol: "arrow.up.left.and.down.right.magnifyingglass", free: false) {
                        AnyView(FocusFlexibilityView())
                    }
                    toolLink(title: "Blink trainer", subtitle: "A paced reminder to blink fully and ease screen dryness.",
                             symbol: "eye", free: false) {
                        AnyView(BlinkTrainerView())
                    }
                    BreakConfigCard()
                }
                .padding(16)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Tools")
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
    }

    private var disclaimerBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("These are comfort and self-monitoring tools — not a medical eye exam. See an optometrist for any vision concerns.")
                .font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(fill: Theme.accentSoft)
    }

    @ViewBuilder
    private func toolLink(title: String, subtitle: String, symbol: String, free: Bool,
                          @ViewBuilder destination: @escaping () -> AnyView) -> some View {
        let unlocked = free || isPro
        if unlocked {
            NavigationLink {
                destination()
            } label: {
                toolRow(title: title, subtitle: subtitle, symbol: symbol, locked: false)
            }
            .buttonStyle(.plain)
        } else {
            Button { paywallReason = .toolLocked } label: {
                toolRow(title: title, subtitle: subtitle, symbol: symbol, locked: true)
            }
            .buttonStyle(.plain)
        }
    }

    private func toolRow(title: String, subtitle: String, symbol: String, locked: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.accentSoft).frame(width: 52, height: 52)
                Image(systemName: symbol).font(.system(size: 22)).foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title).font(Theme.rounded(16, .semibold)).foregroundStyle(Theme.ink)
                    if locked { ProLockChip() }
                }
                Text(subtitle).font(Theme.rounded(13)).foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle)\(locked ? ", Pro feature" : "")")
    }
}

/// Inline card to configure the 20-20-20 rhythm and daily goal (mirrors Settings).
private struct BreakConfigCard: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Break rhythm", systemImage: "slider.horizontal.3")
            Stepper(value: Binding(
                get: { settings.breakIntervalMinutes },
                set: { settings.breakIntervalMinutes = min(120, max(5, $0)) }
            ), in: 5...120, step: 5) {
                HStack {
                    Text("Break every").foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(settings.breakIntervalMinutes) min").foregroundStyle(Theme.inkSoft)
                }
            }
            .accessibilityValue("\(settings.breakIntervalMinutes) minutes")

            Stepper(value: Binding(
                get: { settings.dailyBreakGoal },
                set: { settings.dailyBreakGoal = min(40, max(1, $0)) }
            ), in: 1...40) {
                HStack {
                    Text("Daily goal").foregroundStyle(Theme.ink)
                    Spacer()
                    Text("\(settings.dailyBreakGoal) breaks").foregroundStyle(Theme.inkSoft)
                }
            }
            .accessibilityValue("\(settings.dailyBreakGoal) breaks")

            Text("The classic 20-20-20 rule is a 20-minute interval. Adjust to fit your day.")
                .font(Theme.rounded(12)).foregroundStyle(Theme.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .cardSurface()
    }
}
