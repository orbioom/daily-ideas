import SwiftUI
import SwiftData

/// The Alarms tab: a big "next alarm" header, the list of alarms with per-row enable toggle,
/// next-fire subtitle, swipe-to-delete, and an empty state. Add/Edit via a sheet.
struct AlarmsScreen: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var ring: RingController
    @EnvironmentObject private var notifications: NotificationManager
    @AppStorage("isPro") private var isPro = false

    @Query(sort: \Alarm.createdAt, order: .forward) private var alarms: [Alarm]

    @State private var editing: Alarm?
    @State private var showingNew = false
    @State private var paywallReason: PaywallReason?

    /// Ticks every second so countdown labels stay live.
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var sorted: [Alarm] {
        AlarmScheduler.sortedByNextFire(alarms, reference: now)
    }

    var body: some View {
        NavigationStack {
            Group {
                if alarms.isEmpty {
                    EmptyStateView(symbol: "alarm",
                                   title: "No alarms yet",
                                   message: "Add your first alarm and pick a dismiss mission that gets you out of bed.",
                                   actionTitle: "Add an alarm") { showingNew = true }
                        .frame(maxHeight: .infinity)
                        .background(Theme.bg.ignoresSafeArea())
                } else {
                    list
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.select(settings.hapticsEnabled)
                        showingNew = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add alarm")
                }
            }
            .sheet(isPresented: $showingNew) {
                AlarmEditScreen(alarm: nil)
            }
            .sheet(item: $editing) { alarm in
                AlarmEditScreen(alarm: alarm)
            }
            .sheet(item: $paywallReason) { PaywallView(reason: $0) }
        }
        .onReceive(ticker) { now = $0 }
    }

    // MARK: List

    private var list: some View {
        List {
            Section {
                header
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section {
                ForEach(sorted) { alarm in
                    AlarmRow(alarm: alarm, now: now,
                             use24Hour: settings.use24Hour,
                             onToggle: { toggle(alarm) },
                             onTest: { startTest(alarm) })
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .contentShape(Rectangle())
                        .onTapGesture { editing = alarm }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { delete(alarm) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button { startTest(alarm) } label: {
                                Label("Test", systemImage: "play.fill")
                            }
                            .tint(Theme.accent)
                        }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.bg.ignoresSafeArea())
    }

    private var header: some View {
        let soonest = AlarmScheduler.soonestFire(alarms, reference: now)
        return CardView {
            VStack(alignment: .leading, spacing: 8) {
                if let soonest {
                    HStack(spacing: 8) {
                        Image(systemName: "alarm.waves.left.and.right.fill")
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                        Text("Next alarm")
                            .font(Theme.rounded(14, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    Text(AlarmScheduler.countdownLabel(to: soonest.date, from: now))
                        .font(Theme.rounded(40, .bold))
                        .foregroundStyle(Theme.ink)
                        .contentTransition(.numericText())
                    Text("\(soonest.alarm.label) · \(TimeFormat.clock(hour: soonest.alarm.hour, minute: soonest.alarm.minute, use24Hour: settings.use24Hour))")
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.inkSoft)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundStyle(Theme.inkFaint)
                            .accessibilityHidden(true)
                        Text("No alarms enabled")
                            .font(Theme.rounded(18, .semibold))
                            .foregroundStyle(Theme.ink)
                    }
                    Text("Turn an alarm on, or add a new one, and it'll appear here.")
                        .font(Theme.rounded(14))
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(headerAccessibility(soonest))
        }
    }

    private func headerAccessibility(_ soonest: (alarm: Alarm, date: Date)?) -> String {
        guard let soonest else { return "No alarms enabled" }
        return "Next alarm \(soonest.alarm.label), rings in \(AlarmScheduler.countdownLabel(to: soonest.date, from: now))"
    }

    // MARK: Actions

    private func toggle(_ alarm: Alarm) {
        alarm.isEnabled.toggle()
        try? context.save()
        Haptics.select(settings.hapticsEnabled)
        notifications.scheduleBackstop(for: alarm)
    }

    private func delete(_ alarm: Alarm) {
        Haptics.warning(settings.hapticsEnabled)
        notifications.cancelBackstop(for: alarm)
        context.delete(alarm)
        try? context.save()
    }

    private func startTest(_ alarm: Alarm) {
        if !isPro && (!alarm.missionType.isFree || !SoundLibrary.sound(named: alarm.soundName).isFree) {
            paywallReason = !alarm.missionType.isFree ? .mission(alarm.missionType) : .sound(alarm.soundName)
            return
        }
        Haptics.thump(settings.hapticsEnabled)
        ring.startRinging(alarm, test: true)
    }
}
