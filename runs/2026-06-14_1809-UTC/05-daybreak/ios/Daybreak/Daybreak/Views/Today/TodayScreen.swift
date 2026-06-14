import SwiftUI
import SwiftData

/// Today: dawn greeting header, routines for the current time-of-day surfaced first,
/// an overall streak ring, and a fast Start into the guided player.
struct TodayScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Routine.sortOrder) private var routines: [Routine]
    @Query(sort: \RoutineRun.date, order: .reverse) private var runs: [RoutineRun]

    @State private var playerRoutine: Routine?
    @State private var showTemplates = false
    @State private var paywallReason: PaywallReason?

    private var currentTOD: TimeOfDay { TimeOfDay.current() }

    /// Routines ordered with the current time-of-day first, then by sortOrder.
    private var orderedRoutines: [Routine] {
        routines.sorted { lhs, rhs in
            let lp = lhs.timeOfDay == currentTOD ? 0 : 1
            let rp = rhs.timeOfDay == currentTOD ? 0 : 1
            if lp != rp { return lp < rp }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private var streak: Int {
        RoutineEngine.overallStreak(runs: runs,
                                    threshold: settings.completionThreshold,
                                    calendar: settings.calendar)
    }

    /// Fraction of routines run today, for the ring fill (guarded).
    private var todayProgress: Double {
        guard !routines.isEmpty else { return 0 }
        let done = routines.filter { status(for: $0) == .done }.count
        return Double(done) / Double(routines.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if routines.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            header
                            ForEach(orderedRoutines) { routine in
                                RoutineCard(routine: routine,
                                            status: status(for: routine)) {
                                    Haptics.tap(settings.hapticsEnabled)
                                    playerRoutine = routine
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $playerRoutine) { routine in
                PlayerView(routine: routine)
            }
            .sheet(isPresented: $showTemplates) {
                TemplatesGalleryView(onCreate: createFromTemplate(_:))
            }
            .sheet(item: $paywallReason) { reason in
                PaywallView(reason: reason)
            }
        }
    }

    private func createFromTemplate(_ template: RoutineTemplate) {
        if (template.isPro && !isPro) || !Pro.canAddRoutine(currentCount: routines.count, isPro: isPro) {
            showTemplates = false
            paywallReason = .routineLimit
            return
        }
        let next = (routines.map(\.sortOrder).max() ?? -1) + 1
        let routine = template.makeRoutine(sortOrder: next)
        context.insert(routine)
        try? context.save()
        Haptics.success(settings.hapticsEnabled)
        showTemplates = false
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(Theme.rounded(26, .bold))
                        .foregroundStyle(Theme.onHeader)
                    Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                        .font(Theme.rounded(15, .medium))
                        .foregroundStyle(Theme.onHeader.opacity(0.85))
                }
                Spacer()
                StreakRing(streak: streak, progress: ringProgress, size: 84)
                    .padding(6)
                    .background(Circle().fill(Theme.surface.opacity(0.85)))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.dawnGradient)
        )
        .accessibilityElement(children: .combine)
    }

    /// Use today's completion as the ring fill so it visibly fills as routines are done.
    private var ringProgress: Double {
        // Blend a little of the streak so an existing streak shows a partly-full ring at day start.
        max(todayProgress, streak > 0 ? 0.08 : 0)
    }

    private var greeting: String {
        switch currentTOD {
        case .morning: return "Good morning"
        case .evening: return "Good evening"
        case .anytime: return "Hello"
        }
    }

    // MARK: Empty

    private var emptyState: some View {
        EmptyStateView(symbol: "sun.haze.fill",
                       title: "Create your first routine",
                       message: "Chain a few small habits into a routine you can run start to finish. Start from a template or build your own.",
                       actionTitle: "Browse templates") {
            showTemplates = true
        }
        .padding(.horizontal, 8)
    }

    // MARK: Helpers

    private func status(for routine: Routine) -> TodayStatus {
        RoutineEngine.todayStatus(routine: routine,
                                  runs: runs,
                                  threshold: settings.completionThreshold,
                                  calendar: settings.calendar)
    }
}
