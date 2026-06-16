import SwiftUI

/// Current Moon phase detail plus the next several principal phases.
struct MoonView: View {
    @Bindable var sky: SkyViewModel
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @State private var upcoming: [(name: MoonPhaseName, date: Date)] = []
    @State private var computingPhases = true

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                content
            }
            .navigationTitle("Moon")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch sky.state {
        case .idle, .loading:
            LoadingView(message: "Reading the Moon…")
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await sky.refresh(settings: settings, isPro: isPro) }
            }
        case .loaded(let snap):
            loaded(snap)
        }
    }

    private func loaded(_ snap: SkySnapshot) -> some View {
        ScrollView {
            VStack(spacing: 18) {
                phaseHero(snap)
                moonNowCard(snap)
                upcomingCard(snap)
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .task(id: snap.context.date.timeIntervalSinceReferenceDate) {
            await computeUpcoming(after: snap.context.date)
        }
    }

    private func phaseHero(_ snap: SkySnapshot) -> some View {
        let phase = snap.moonPhase
        return VStack(spacing: 14) {
            MoonGlyph(illumination: phase.illumination, waxing: phase.isWaxing, size: 150)
                .shadow(color: Theme.gold.opacity(0.35), radius: 24)
                .accessibilityHidden(true)
            Text(phase.name.rawValue)
                .font(Theme.rounded(26, .bold))
                .foregroundStyle(Theme.ink)
            Text("\(phase.illuminationPercent)% illuminated • \(phase.isWaxing ? "waxing" : "waning")")
                .font(.callout)
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Moon is \(phase.name.rawValue), \(phase.illuminationPercent) percent illuminated and \(phase.isWaxing ? "waxing" : "waning").")
    }

    private func moonNowCard(_ snap: SkySnapshot) -> some View {
        let moon = snap.planets.first(where: { $0.body == .moon })
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "The Moon now", systemImage: "moon.fill")
            if let moon {
                HStack {
                    miniStat("Position", moon.isAboveHorizon ? moon.horizontal.compass16 : "Below",
                             moon.isAboveHorizon ? Theme.accent : Theme.inkSoft)
                    miniStat("Altitude", Fmt.altitude(moon.horizontal.altitude),
                             moon.isAboveHorizon ? Theme.good : Theme.inkSoft)
                    miniStat("Elongation", Fmt.deg(snap.moonPhase.phaseAngle), Theme.gold)
                }
                NavigationLink {
                    ObjectDetailView(object: moon, context: snap.context)
                } label: {
                    HStack {
                        Text("Rise, transit & set times")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.inkFaint)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func upcomingCard(_ snap: SkySnapshot) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Upcoming phases", systemImage: "calendar")
            if computingPhases {
                HStack { ProgressView().tint(Theme.accent); Text("Calculating…").font(.footnote).foregroundStyle(Theme.inkSoft) }
            } else if upcoming.isEmpty {
                Text("Phase predictions are unavailable for this date.")
                    .font(.footnote).foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(Array(upcoming.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 12) {
                        MoonGlyph(illumination: illumination(for: item.name),
                                  waxing: waxing(for: item.name), size: 32)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name.rawValue).font(Theme.rounded(15, .semibold)).foregroundStyle(Theme.ink)
                            Text(Fmt.dateTime(item.date, timeZone: snap.context.timeZone))
                                .font(.caption).foregroundStyle(Theme.inkSoft)
                        }
                        Spacer()
                        Text(relativeDays(to: item.date, from: snap.context.date))
                            .font(.caption2).foregroundStyle(Theme.inkFaint)
                    }
                    .padding(.vertical, 3)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.name.rawValue) on \(Fmt.dateTime(item.date, timeZone: snap.context.timeZone))")
                }
            }
        }
        .padding(16)
        .cardSurface()
    }

    private func miniStat(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(Theme.rounded(17, .bold)).foregroundStyle(tint)
            Text(title).font(.caption2).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

    private func computeUpcoming(after date: Date) async {
        computingPhases = true
        let result = await Task.detached(priority: .userInitiated) {
            MoonPhaseEngine.nextPrincipalPhases(after: date, count: 6)
        }.value
        upcoming = result
        computingPhases = false
    }

    private func illumination(for name: MoonPhaseName) -> Double {
        switch name {
        case .newMoon: return 0.02
        case .firstQuarter, .lastQuarter: return 0.5
        case .fullMoon: return 1.0
        default: return 0.3
        }
    }

    private func waxing(for name: MoonPhaseName) -> Bool {
        switch name {
        case .newMoon, .firstQuarter, .waxingCrescent, .waxingGibbous: return true
        default: return false
        }
    }

    private func relativeDays(to target: Date, from now: Date) -> String {
        let days = Int((target.timeIntervalSince(now) / 86400).rounded())
        if days <= 0 { return "today" }
        if days == 1 { return "tomorrow" }
        return "in \(days)d"
    }
}
