import SwiftUI
import SwiftData

/// Live tracking for one active cook: big elapsed timer, target vs latest temp with
/// a doneness state, the phase timeline, stall hint, done-by / rest-until estimates,
/// quick temp logging, and resting / done actions.
///
/// The timer is wall-clock: it reads `cook.startDate` through a TimelineView and
/// re-anchors on `scenePhase`, so it stays correct across backgrounding and relaunch.
struct LiveCookView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var cook: Cook

    @State private var showLog = false
    @State private var showRating = false
    @State private var anchor = Date()   // bumped on scenePhase to force re-evaluation

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    timerCard
                    tempCard
                    if showStallHint {
                        stallHint
                    }
                    estimatesCard
                    timelineCard
                    actionButtons
                }
                .padding(16)
            }
        }
        .navigationTitle(cook.name)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: scenePhase) { _, newPhase in
            // Re-anchor when returning to the foreground so the wall-clock timer is fresh.
            if newPhase == .active { anchor = Date() }
        }
        .sheet(isPresented: $showLog) { LogTempSheet(cook: cook) }
        .sheet(isPresented: $showRating) { RateCookSheet(cook: cook) }
    }

    // MARK: Derived values

    private var guide: GuideEntry? {
        DonenessGuide.entry(protein: cook.protein, cut: cook.cut)
    }

    private var totalMinutes: Double {
        CookEngine.estimatedTotalMinutes(weightKg: cook.weightKg, method: cook.method, guide: guide)
    }

    private var restMinutes: Int { guide?.restMinutes ?? 10 }

    private var riseRate: Double? {
        CookEngine.recentRiseCPerMin(logs: cook.tempLogs)
    }

    private var stalling: Bool {
        CookEngine.isStalling(method: cook.method,
                              status: cook.status,
                              currentC: cook.latestInternalTempC,
                              recentRiseCPerMin: riseRate)
    }

    private var showStallHint: Bool {
        stalling && settings.stallAlertsEnabled
    }

    // MARK: Cards

    private var timerCard: some View {
        TimelineView(.periodic(from: anchor, by: 1)) { ctx in
            let elapsed = elapsedSeconds(now: ctx.date)
            VStack(spacing: 6) {
                Text(cook.status == .resting ? "Resting" : "Elapsed")
                    .font(Theme.rounded(13, .semibold))
                    .foregroundStyle(Theme.inkSoft)
                    .textCase(.uppercase)
                Text(formatDuration(elapsed))
                    .font(Theme.numeral(52, .heavy))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .accessibilityLabel("Elapsed \(accessibleDuration(elapsed))")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface)
                    GrateBackground()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            )
        }
    }

    private var tempCard: some View {
        let current = cook.latestInternalTempC
        let state = TempEngine.classify(currentC: current, targetC: cook.targetInternalTempC, status: cook.status)
        return VStack(spacing: 14) {
            HStack(alignment: .top) {
                tempColumn(title: "Current", value: current.map { settings.tempNumeral($0) } ?? "—", tint: Theme.ink)
                Spacer()
                tempColumn(title: "Target", value: settings.tempNumeral(cook.targetInternalTempC), tint: Theme.accent)
            }
            HStack(spacing: 8) {
                Image(systemName: state.symbol)
                    .foregroundStyle(state.hue)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(state.label)
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(state.hue)
                    Text(state.detail)
                        .font(Theme.rounded(12))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(state.hue.opacity(0.12)))
        }
        .searCard()
    }

    private func tempColumn(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.rounded(12, .semibold))
                .foregroundStyle(Theme.inkSoft)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(Theme.numeral(40, .heavy))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                Text(settings.tempUnitSuffix)
                    .font(Theme.rounded(18, .bold))
                    .foregroundStyle(tint.opacity(0.7))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value) \(settings.tempUnitSuffix)")
    }

    private var stallHint: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.bubble.fill")
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("The stall — consider wrapping")
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.warn)
                Text("Evaporative cooling has slowed the climb. Foil or butcher paper will push through it.")
                    .font(Theme.rounded(12))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .searCard()
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.warn.opacity(0.4), lineWidth: 1))
    }

    private var estimatesCard: some View {
        HStack(spacing: 12) {
            estimate(title: "Done by", value: doneByText, symbol: "checkmark.circle")
            estimate(title: "Rest until", value: restUntilText, symbol: "pause.circle")
        }
    }

    private func estimate(title: String, value: String, symbol: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(title)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .searCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value)")
    }

    private var timelineCard: some View {
        let elapsed = elapsedSeconds(now: Date())
        let phase = CookEngine.currentPhase(method: cook.method,
                                            status: cook.status,
                                            elapsed: elapsed,
                                            totalMinutes: totalMinutes,
                                            currentC: cook.latestInternalTempC,
                                            targetC: cook.targetInternalTempC,
                                            stalling: stalling)
        let steps = CookEngine.timeline(method: cook.method, current: phase)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Phase timeline")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.ink)
            PhaseTimelineView(steps: steps)
        }
        .searCard()
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button { showLog = true } label: {
                Label("Log temp", systemImage: "plus.circle.fill")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.accentSoft))
            }
            if cook.status == .cooking {
                Button { startResting() } label: {
                    Label("Start resting", systemImage: "pause.fill")
                        .font(Theme.rounded(16, .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.surfaceAlt))
                }
            }
            PrimaryButton(title: "Mark done (rate it)", systemImage: "checkmark.seal.fill") {
                showRating = true
            }
        }
    }

    // MARK: Timer math

    private func elapsedSeconds(now: Date) -> TimeInterval {
        if cook.status == .resting {
            return CookEngine.elapsedSeconds(start: cook.restStartDate, now: now)
        }
        return CookEngine.elapsedSeconds(start: cook.startDate, now: now)
    }

    private var doneByText: String {
        guard let date = CookEngine.doneByDate(start: cook.startDate, totalMinutes: totalMinutes) else { return "—" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    private var restUntilText: String {
        let restStart = cook.restStartDate ?? CookEngine.doneByDate(start: cook.startDate, totalMinutes: totalMinutes)
        guard let date = CookEngine.restUntilDate(restStart: restStart, restMinutes: restMinutes) else { return "—" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    // MARK: Actions

    private func startResting() {
        cook.status = .resting
        cook.restStartDate = Date()
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
    }

    // MARK: Formatting

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    private func accessibleDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h) hours \(m) minutes" }
        return "\(m) minutes"
    }
}
