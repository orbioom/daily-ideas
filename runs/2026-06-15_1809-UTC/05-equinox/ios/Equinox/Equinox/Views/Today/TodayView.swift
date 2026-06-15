import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: AppSettings
    @Query(sort: \DayLog.date, order: .reverse) private var allLogs: [DayLog]

    @State private var todayLog: DayLog?
    @State private var showSettings = false
    @State private var savedPulse = false
    @State private var loadFailed = false

    private var engine: InsightsEngine { InsightsEngine(logs: allLogs) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    if let log = todayLog {
                        DayLogEditor(log: log, onChange: handleChange)
                    } else if loadFailed {
                        errorCard
                    } else {
                        loadingCard
                    }
                    footerNote
                }
                .padding(16)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .overlay(alignment: .top) { savedToast }
            .onAppear(perform: ensureTodayLog)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        let cycle = engine.cycleInfo()
        let streak = engine.loggingStreak()
        return VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(Theme.serif(24, .semibold))
                        .foregroundStyle(.white)
                    Text(Date().formatted(date: .complete, time: .omitted))
                        .font(Theme.rounded(13))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                BotanicalSprig(size: 26, color: .white)
            }
            HStack(spacing: 12) {
                miniStat(value: "\(streak)", label: streak == 1 ? "day streak" : "day streak", symbol: "flame.fill")
                if settings.trackCycle {
                    miniStat(value: cycleValue(cycle), label: "since period", symbol: "calendar")
                }
                miniStat(value: "\(todayLog?.hotFlashCount ?? 0)", label: "flashes today", symbol: "thermometer.sun.fill")
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .fill(Theme.heroGradient)
        )
        .accessibilityElement(children: .contain)
    }

    private func miniStat(value: String, label: String, symbol: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
            Text(value)
                .font(Theme.rounded(20, .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(Theme.rounded(11))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerSmall, style: .continuous)
                .fill(Color.white.opacity(0.16))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private func cycleValue(_ cycle: InsightsEngine.CycleInfo) -> String {
        guard let d = cycle.daysSinceLastPeriod else { return "—" }
        return "\(d)d"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Resting easy"
        }
    }

    // MARK: - Loading / error

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Preparing today's check-in…")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .cardSurface()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading today's check-in")
    }

    private var errorCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
            Text("We couldn't open today's entry")
                .font(Theme.rounded(17, .semibold))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
            Text("Your saved data is safe. Try again in a moment.")
                .font(Theme.rounded(14))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
            SecondaryButton(title: "Try again", systemImage: "arrow.clockwise") {
                loadFailed = false
                ensureTodayLog()
            }
            .frame(maxWidth: 220)
        }
        .padding(28)
        .cardSurface()
    }

    private var footerNote: some View {
        Text("Equinox is a companion, not a diagnosis. Share patterns with your clinician.")
            .font(Theme.rounded(12))
            .foregroundStyle(Theme.inkFaint)
            .multilineTextAlignment(.center)
            .padding(.top, 4)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Saved toast

    private var savedToast: some View {
        Group {
            if savedPulse {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Saved")
                        .font(Theme.rounded(14, .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Theme.good))
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .accessibilityLabel("Saved")
            }
        }
    }

    // MARK: - Logic

    private func ensureTodayLog() {
        guard todayLog == nil else { return }
        let log = DayLogStore.logOrCreate(on: Date(), context: modelContext)
        // If the fetch path somehow returned a transient object that isn't persisted, still usable.
        todayLog = log
        if todayLog == nil { loadFailed = true }
    }

    private func handleChange() {
        DayLogStore.save(modelContext)
        showSaved()
    }

    private func showSaved() {
        Haptics.success(enabled: settings.hapticsEnabled)
        withAnimation(.easeInOut(duration: 0.25)) { savedPulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.3)) { savedPulse = false }
        }
    }
}
