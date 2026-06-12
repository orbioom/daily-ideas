import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(PedometerService.self) private var pedometer
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \DayLog.day, order: .reverse) private var logs: [DayLog]

    @AppStorage("dailyGoal") private var dailyGoal = 10_000
    @AppStorage("unitsRaw") private var unitsRaw = Units.metric.rawValue
    @AppStorage("weightKg") private var weightKg = 70.0
    @AppStorage("useSampleData") private var useSampleData = false

    @State private var didSync = false
    @State private var newBadge: BadgeDef?

    private var units: Units { Units(rawValue: unitsRaw) ?? .metric }

    private var todaySteps: Int {
        if useSampleData { return logs.first(where: { Calendar.current.isDateInToday($0.day) })?.steps ?? 0 }
        return pedometer.today.steps
    }
    private var todayDistance: Double {
        if useSampleData { return logs.first(where: { Calendar.current.isDateInToday($0.day) })?.distanceMeters ?? 0 }
        return pedometer.today.distanceMeters
    }
    private var todayFlights: Int {
        if useSampleData { return logs.first(where: { Calendar.current.isDateInToday($0.day) })?.flights ?? 0 }
        return pedometer.today.flights
    }
    private var progress: Double { dailyGoal > 0 ? Double(todaySteps) / Double(dailyGoal) : 0 }
    private var streak: Int { StepEngine.currentStreak(logs: logs) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()
                content
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if streak > 0 {
                        Label("\(streak)", systemImage: "flame.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.warm)
                            .accessibilityLabel("\(streak) day streak")
                    }
                }
            }
        }
        .task { await sync() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await sync() } }
        }
        .onChange(of: pedometer.today) { _, _ in persistToday() }
        .onChange(of: useSampleData) { _, _ in Task { didSync = false; await sync() } }
        .overlay(alignment: .bottom) {
            if let b = newBadge { BadgeToast(def: b) { newBadge = nil } }
        }
    }

    @ViewBuilder private var content: some View {
        switch pedometer.phase {
        case .unavailable where !useSampleData:
            EmptyStateView(symbol: "iphone.slash",
                           title: "No motion sensor",
                           message: "This device can't count steps. Turn on Demo Data in Settings to explore Tread with a sample week.",
                           actionTitle: "Open Settings hint", action: nil)
        case .denied where !useSampleData:
            EmptyStateView(symbol: "hand.raised.fill",
                           title: "Motion access is off",
                           message: "Tread needs Motion & Fitness access to count your steps. Enable it in Settings ▸ Privacy ▸ Motion & Fitness ▸ Tread.")
        default:
            scrollBody
        }
    }

    private var scrollBody: some View {
        ScrollView {
            VStack(spacing: 16) {
                StepRing(progress: progress, steps: todaySteps, goal: dailyGoal, animate: true)
                    .frame(height: 300)
                    .padding(.top, 8)

                HStack(spacing: 12) {
                    StatTile(symbol: "point.topleft.down.to.point.bottomright.curvepath",
                             value: "\(Fmt.distance(todayDistance, units: units)) \(units.shortDistance)",
                             label: "Distance")
                    StatTile(symbol: "flame.fill",
                             value: "\(Fmt.calories(steps: todaySteps, distanceMeters: todayDistance, weightKg: weightKg))",
                             label: "Calories", tint: Theme.warm)
                }
                HStack(spacing: 12) {
                    StatTile(symbol: "stairs",
                             value: "\(todayFlights)",
                             label: "Flights climbed")
                    StatTile(symbol: "flag.checkered",
                             value: "\(max(0, dailyGoal - todaySteps))",
                             label: progress >= 1 ? "Goal met!" : "Steps to go",
                             tint: progress >= 1 ? Theme.accent : Theme.textSecondary)
                }

                encouragement
                    .padding(.top, 4)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private var encouragement: some View {
        let msg: String = {
            if progress >= 1 { return "Goal smashed. Every extra step is a bonus today." }
            if progress >= 0.66 { return "Almost there — a short walk closes the ring." }
            if progress >= 0.25 { return "Good momentum. Keep the streak alive." }
            return "A few minutes on your feet gets things moving."
        }()
        return Text(msg)
            .font(.callout)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .treadCard()
    }

    // MARK: - Data sync

    @MainActor
    private func sync() async {
        if useSampleData {
            if !logs.contains(where: { !$0.fromSensor }) {
                SampleData.install(goal: dailyGoal, context: context)
            }
            checkBadges()
            return
        }
        // In real-sensor mode, clear any leftover demo data.
        SampleData.removeAll(context: context)
        pedometer.start()
        guard !didSync else { persistToday(); checkBadges(); return }
        didSync = true
        let history = await pedometer.fetchHistory(days: 7)
        HistoryStore.upsert(history, goal: dailyGoal, fromSensor: true, context: context)
        persistToday()
        checkBadges()
    }

    @MainActor
    private func persistToday() {
        guard !useSampleData else { return }
        let t = pedometer.today
        guard t.steps > 0 else { return }
        HistoryStore.upsert([t], goal: dailyGoal, fromSensor: true, context: context)
    }

    @MainActor
    private func checkBadges() {
        let unlocked = HistoryStore.syncBadges(logs: logs, context: context)
        if let first = unlocked.first {
            Haptics.success()
            withAnimation { newBadge = first }
        }
    }
}

struct BadgeToast: View {
    let def: BadgeDef
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: def.symbol)
                .font(.title2)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Badge unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(def.title)
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(.white.opacity(0.8))
            }
            .accessibilityLabel("Dismiss")
        }
        .padding()
        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
        .padding()
        .shadow(radius: 8, y: 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .task {
            try? await Task.sleep(for: .seconds(3.5))
            withAnimation { dismiss() }
        }
    }
}
