import SwiftUI
import SwiftData

struct HomeView: View {
    @AppStorage("cradle.activeBaby") private var activeBabyID = ""
    @AppStorage("cradle.unit") private var unitRaw = "ml"
    @AppStorage("cradle.clock24") private var use24h = false

    @Environment(\.modelContext) private var context
    @Query(sort: \Baby.order) private var babies: [Baby]

    @State private var showFeedSheet = false
    @State private var showSleepSheet = false
    @State private var showDiaperSheet = false
    @State private var showPumpSheet = false
    @State private var showNoteSheet = false

    private var useOz: Bool { unitRaw == "oz" }

    private var activeBaby: Baby? {
        if let baby = babies.first(where: { $0.id.uuidString == activeBabyID }) {
            return baby
        }
        return babies.first
    }

    private var events: [CareEvent] {
        activeBaby?.events ?? []
    }

    private var activeEvent: CareEvent? {
        CradleEngine.activeEvent(in: events)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground

                ScrollView {
                    VStack(spacing: 20) {
                        // Baby selector (if multiple)
                        if babies.count > 1 {
                            BabySelectorBar(babies: babies, selectedID: $activeBabyID)
                                .padding(.top, 8)
                        }

                        // Active timer banner
                        if let active = activeEvent {
                            ActiveTimerBanner(event: active) {
                                stopEvent(active)
                            }
                            .padding(.horizontal, 20)
                        }

                        // Baby info header
                        if let baby = activeBaby {
                            babyHeader(baby)
                                .padding(.horizontal, 20)
                        }

                        // Last-event tiles
                        lastEventGrid
                            .padding(.horizontal, 20)

                        // Quick actions
                        quickActionsSection
                            .padding(.horizontal, 20)

                        // Today summary
                        todaySummary
                            .padding(.horizontal, 20)

                        Spacer(minLength: 32)
                    }
                }
            }
            .navigationTitle("Cradle")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showFeedSheet) {
                AddEventSheet(
                    defaultKind: .feed,
                    baby: activeBaby
                )
            }
            .sheet(isPresented: $showSleepSheet) {
                AddEventSheet(
                    defaultKind: .sleep,
                    baby: activeBaby
                )
            }
            .sheet(isPresented: $showDiaperSheet) {
                DiaperQuickSheet(baby: activeBaby)
            }
            .sheet(isPresented: $showPumpSheet) {
                AddEventSheet(
                    defaultKind: .pump,
                    baby: activeBaby
                )
            }
            .sheet(isPresented: $showNoteSheet) {
                AddEventSheet(
                    defaultKind: .note,
                    baby: activeBaby
                )
            }
            .onAppear {
                // Ensure activeBabyID is populated if empty
                if activeBabyID.isEmpty, let first = babies.first {
                    activeBabyID = first.id.uuidString
                }
            }
            .onChange(of: babies) { _, newBabies in
                if activeBabyID.isEmpty, let first = newBabies.first {
                    activeBabyID = first.id.uuidString
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private func babyHeader(_ baby: Baby) -> some View {
        HStack(spacing: 14) {
            BabyAvatar(baby: baby, size: 50)

            VStack(alignment: .leading, spacing: 2) {
                Text(baby.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.text)
                Text(baby.ageString)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(baby.name), \(baby.ageString) old")
    }

    @ViewBuilder
    private var lastEventGrid: some View {
        VStack(spacing: 0) {
            Eyebrow(text: "Last events")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 12
            ) {
                LastEventTile(
                    kind: .feed,
                    event: CradleEngine.lastEvent(of: .feed, in: events),
                    useOz: useOz,
                    use24h: use24h
                )
                LastEventTile(
                    kind: .sleep,
                    event: CradleEngine.lastEvent(of: .sleep, in: events),
                    useOz: useOz,
                    use24h: use24h
                )
                LastEventTile(
                    kind: .diaper,
                    event: CradleEngine.lastEvent(of: .diaper, in: events),
                    useOz: useOz,
                    use24h: use24h
                )
                LastEventTile(
                    kind: .pump,
                    event: CradleEngine.lastEvent(of: .pump, in: events),
                    useOz: useOz,
                    use24h: use24h
                )
            }
        }
    }

    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(spacing: 0) {
            Eyebrow(text: "Quick log")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                QuickActionButton(
                    kind: .feed,
                    isActive: activeEvent?.kind == .feed
                ) {
                    handleFeedTap()
                }
                QuickActionButton(
                    kind: .sleep,
                    isActive: activeEvent?.kind == .sleep
                ) {
                    handleSleepTap()
                }
                QuickActionButton(
                    kind: .diaper,
                    isActive: false
                ) {
                    Haptics.tap()
                    showDiaperSheet = true
                }
                QuickActionButton(
                    kind: .pump,
                    isActive: activeEvent?.kind == .pump
                ) {
                    handlePumpTap()
                }
            }
        }
    }

    @ViewBuilder
    private var todaySummary: some View {
        let summary = CradleEngine.daySummary(events: events, day: Date())
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Eyebrow(text: "Today")

                HStack(spacing: 0) {
                    SummaryCell(
                        value: "\(summary.feeds)",
                        label: "Feeds",
                        symbol: "drop.fill",
                        color: EventKind.feed.color
                    )
                    Divider().frame(height: 36).padding(.horizontal, 8)
                    SummaryCell(
                        value: Format.duration(summary.totalSleep),
                        label: "Sleep",
                        symbol: "moon.fill",
                        color: EventKind.sleep.color
                    )
                    Divider().frame(height: 36).padding(.horizontal, 8)
                    SummaryCell(
                        value: "\(summary.wetDiapers + summary.dirtyDiapers)",
                        label: "Diapers",
                        symbol: "heart.fill",
                        color: EventKind.diaper.color
                    )
                    if summary.bottleML > 0 {
                        Divider().frame(height: 36).padding(.horizontal, 8)
                        SummaryCell(
                            value: Format.amount(summary.bottleML, useOz: useOz),
                            label: "Bottle",
                            symbol: "drop.circle.fill",
                            color: Brand.info
                        )
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today: \(summary.feeds) feeds, \(Format.duration(summary.totalSleep)) sleep, \(summary.wetDiapers + summary.dirtyDiapers) diapers")
    }

    // MARK: - Actions

    private func handleFeedTap() {
        if let active = activeEvent, active.kind == .feed {
            stopEvent(active)
        } else {
            Haptics.tap()
            showFeedSheet = true
        }
    }

    private func handleSleepTap() {
        if let active = activeEvent, active.kind == .sleep {
            stopEvent(active)
        } else if activeEvent == nil {
            // Start a sleep timer immediately
            Haptics.tap()
            guard let baby = activeBaby else { return }
            let event = CareEvent(kind: .sleep, startTime: Date(), endTime: nil, baby: baby)
            context.insert(event)
            baby.events.append(event)
            Haptics.success()
        } else {
            Haptics.tap()
            showSleepSheet = true
        }
    }

    private func handlePumpTap() {
        if let active = activeEvent, active.kind == .pump {
            stopEvent(active)
        } else {
            Haptics.tap()
            showPumpSheet = true
        }
    }

    private func stopEvent(_ event: CareEvent) {
        event.endTime = Date()
        Haptics.success()
    }
}

// MARK: - SummaryCell

private struct SummaryCell: View {
    let value: String
    let label: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .accessibilityHidden(true)
            Text(value)
                .font(Brand.mono(15, weight: .semibold))
                .foregroundStyle(Brand.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity)
    }
}
