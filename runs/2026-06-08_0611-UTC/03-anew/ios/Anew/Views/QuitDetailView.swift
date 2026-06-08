import SwiftUI
import SwiftData

struct QuitDetailView: View {
    @Bindable var quit: Quit

    @AppStorage("anew.currency") private var currencySymbol: String = "$"
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: DetailTab = .milestones
    @State private var showEditQuit = false
    @State private var showAddCheckIn = false
    @State private var showRelapseConfirm = false
    @State private var relapseNote = ""
    @State private var showRelapseSheet = false

    enum DetailTab: String, CaseIterable {
        case milestones = "Milestones"
        case health     = "Health"
        case journal    = "Journal"
    }

    var body: some View {
        ZStack {
            Brand.pageBackground

            ScrollView {
                VStack(spacing: 20) {
                    // Hero live counter
                    heroSection

                    // Stats row
                    statsRow

                    // Segmented tabs
                    segmentedPicker

                    // Tab content
                    switch selectedTab {
                    case .milestones:
                        MilestonesTabContent(quit: quit)
                    case .health:
                        HealthTabContent(quit: quit)
                    case .journal:
                        JournalTabContent(quit: quit)
                    }

                    // Action buttons
                    actionButtons
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(quit.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditQuit = true
                    Haptics.tap()
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showEditQuit) {
            AddEditQuitView(quit: quit)
        }
        .sheet(isPresented: $showAddCheckIn) {
            AddCheckInView(quit: quit)
        }
        .sheet(isPresented: $showRelapseSheet) {
            RelapseEntryView(quit: quit)
        }
    }

    // MARK: Hero

    private var heroSection: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: quit.colorHex).opacity(0.2))
                            .frame(width: 52, height: 52)
                        Image(systemName: quit.symbol)
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: quit.colorHex))
                    }
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(quit.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Brand.text)
                        Text("Since \(Format.shortDate(quit.startDate))")
                            .font(.caption)
                            .foregroundStyle(Brand.text3)
                    }
                    Spacer()
                    StatusDot(color: quit.active ? Brand.live : Brand.text3)
                }

                LiveCounterView(startDate: quit.startDate, large: true)

                if !quit.motivation.isEmpty {
                    Text(""\(quit.motivation)"")
                        .font(.callout.italic())
                        .foregroundStyle(Brand.text2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            DetailStatCard(
                label: "Money Saved",
                value: Format.currency(
                    SobrietyEngine.moneySaved(quit: quit, now: Date()),
                    symbol: currencySymbol
                ),
                symbol: "dollarsign.circle.fill",
                color: Brand.live
            )
            DetailStatCard(
                label: "Avoided",
                value: Format.unitsAvoided(
                    SobrietyEngine.unitsAvoided(quit: quit, now: Date()),
                    label: quit.unitLabel
                ),
                symbol: "minus.circle.fill",
                color: Brand.info
            )
            DetailStatCard(
                label: "Best Streak",
                value: "\(SobrietyEngine.longestStreak(quit: quit, now: Date()))d",
                symbol: "flame.fill",
                color: Brand.warn
            )
        }
    }

    // MARK: Segment picker

    private var segmentedPicker: some View {
        Picker("Section", selection: $selectedTab) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Text(tab.rawValue).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedTab) { _, _ in Haptics.selection() }
    }

    // MARK: Actions

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                pledgeToday()
            } label: {
                Label("Pledge Today", systemImage: "checkmark.seal.fill")
            }
            .buttonStyle(InkButtonStyle())
            .accessibilityHint("Records today's pledge for \(quit.name)")

            Button {
                showRelapseSheet = true
                Haptics.warning()
            } label: {
                Label("I Had a Slip", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(Brand.danger)
            }
            .buttonStyle(GlassButtonStyle())
            .accessibilityHint("Record a relapse and reset your clean streak")

            Button {
                showAddCheckIn = true
                Haptics.tap()
            } label: {
                Label("Add Check-In", systemImage: "pencil")
            }
            .buttonStyle(GlassButtonStyle())
        }
    }

    // MARK: Pledge

    private func pledgeToday() {
        let today = Calendar.current.startOfDay(for: Date())
        if let existing = quit.checkIns.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            existing.pledged = true
        } else {
            let checkIn = CheckIn(date: today, mood: 4, note: "", pledged: true, quit: quit)
            modelContext.insert(checkIn)
            quit.checkIns.append(checkIn)
        }
        Haptics.success()
    }
}

// MARK: - Detail stat card

private struct DetailStatCard: View {
    let label: String
    let value: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .accessibilityHidden(true)

            Text(value)
                .font(Brand.mono(15, weight: .bold))
                .foregroundStyle(Brand.text)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text(label)
                .font(.caption2)
                .foregroundStyle(Brand.text3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Brand.glassStroke.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Milestones tab

struct MilestonesTabContent: View {
    let quit: Quit

    var body: some View {
        let statuses = SobrietyEngine.milestoneStatuses(quit: quit, now: Date())
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: "Milestones")
                    .padding(.bottom, 12)

                ForEach(statuses) { status in
                    MilestoneRow(status: status)
                    if status.id != statuses.last?.id {
                        Divider()
                            .padding(.vertical, 4)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }
}

// MARK: - Health timeline tab

struct HealthTabContent: View {
    let quit: Quit

    var body: some View {
        let days = SobrietyEngine.cleanDays(start: quit.startDate, now: Date())
        let events = SobrietyEngine.healthTimeline(category: quit.category, cleanDays: days)

        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(text: "Health Recovery")
                    .padding(.bottom, 12)

                ForEach(events) { event in
                    HealthEventRow(event: event)
                    if event.id != events.last?.id {
                        Divider()
                            .padding(.vertical, 4)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
    }
}

private struct HealthEventRow: View {
    let event: HealthEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(event.reached ? Brand.live : Brand.text3.opacity(0.3))
                .frame(width: 10, height: 10)
                .padding(.top, 5)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(event.reached ? Brand.text : Brand.text2)

                Text(event.detail)
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(event.title)
        .accessibilityValue(event.reached ? "Reached" : "Upcoming")
    }
}

// MARK: - Journal tab

struct JournalTabContent: View {
    let quit: Quit

    private var sortedCheckIns: [CheckIn] {
        quit.checkIns.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Eyebrow(text: "Journal")
                    Spacer()
                    Text("\(sortedCheckIns.count) entries")
                        .font(.caption)
                        .foregroundStyle(Brand.text3)
                }
                .padding(.bottom, 12)

                if sortedCheckIns.isEmpty {
                    EmptyStateView(
                        icon: "pencil.and.list.clipboard",
                        title: "No check-ins",
                        message: "Tap 'Add Check-In' below to start your journal."
                    )
                } else {
                    ForEach(sortedCheckIns) { checkIn in
                        CheckInRow(checkIn: checkIn)
                        if checkIn.id != sortedCheckIns.last?.id {
                            Divider()
                                .padding(.vertical, 4)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
    }
}

private struct CheckInRow: View {
    let checkIn: CheckIn

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(Format.moodEmoji(checkIn.mood))
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(Format.moodLabel(checkIn.mood))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Brand.text)
                    if checkIn.pledged {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Brand.live)
                            .accessibilityLabel("Pledged")
                    }
                }
                if !checkIn.note.isEmpty {
                    Text(checkIn.note)
                        .font(.caption)
                        .foregroundStyle(Brand.text2)
                        .lineLimit(3)
                }
                Text(Format.shortDate(checkIn.date))
                    .font(.caption2)
                    .foregroundStyle(Brand.text3)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(Format.shortDate(checkIn.date)): \(Format.moodLabel(checkIn.mood))\(checkIn.note.isEmpty ? "" : ", \(checkIn.note)")")
    }
}
