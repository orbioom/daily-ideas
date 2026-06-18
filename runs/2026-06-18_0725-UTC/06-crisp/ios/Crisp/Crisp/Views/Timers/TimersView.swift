import SwiftUI
import SwiftData

struct TimersView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var pro: ProStore
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(\.modelContext) private var context

    @Query(sort: \CookTimer.createdAt, order: .reverse) private var timers: [CookTimer]

    @State private var showAdd = false
    @State private var showPaywall = false
    @State private var showSettings = false

    private var runningCount: Int {
        timers.filter { $0.isActive && !$0.isFinished() }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()
                if timers.isEmpty {
                    EmptyStateView(
                        symbol: "timer",
                        title: "No timers running",
                        message: "Start a timer from any food, or add a quick custom one to get cooking.",
                        actionTitle: "Add a timer",
                        action: { tryAdd() }
                    )
                } else {
                    timerList
                }
            }
            .navigationTitle("Timers")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { tryAdd() } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add timer")
                }
            }
            .sheet(isPresented: $showAdd) { QuickTimerSheet() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var timerList: some View {
        ScrollView {
            VStack(spacing: 14) {
                if !pro.isPro {
                    capBanner
                }
                ForEach(timers) { timer in
                    TimerCard(timer: timer)
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }

    private var capBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("\(runningCount)/\(ProLimits.freeTimerCap) free timers running")
                .font(Theme.roundedStyle(.footnote, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Button("Go Pro") { showPaywall = true }
                .font(Theme.roundedStyle(.footnote, .bold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .crispCard(radius: Theme.chipRadius)
    }

    private func tryAdd() {
        if runningCount >= pro.timerCap() {
            Haptics.notify(.warning, enabled: settings.hapticsEnabled)
            showPaywall = true
        } else {
            showAdd = true
        }
    }
}
