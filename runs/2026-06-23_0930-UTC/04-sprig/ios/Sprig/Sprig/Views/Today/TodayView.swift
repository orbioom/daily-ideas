import SwiftUI
import SwiftData

/// The home screen: baby header, live breast/sleep timers, quick-add controls,
/// today's summary, and last-event tiles. One tap to log anything.
struct TodayView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.modelContext) private var context
    @AppStorage(PrefKey.volumeUnit) private var volumeUnitRaw = VolumeUnit.oz.rawValue
    @AppStorage(PrefKey.hapticsEnabled) private var haptics = true
    @AppStorage(PrefKey.activeBabyID) private var activeBabyIDString = ""

    @Bindable var baby: Baby

    @Query(sort: \Baby.createdAt) private var allBabies: [Baby]

    // Breast feed timer state (in-memory; the timer drives a live clock).
    @State private var feedTimerStart: Date?
    @State private var feedTimerSide: FeedKind = .breastBoth

    // Sheets
    @State private var sheet: TodaySheet?
    @State private var showSwitcher = false

    private var unit: VolumeUnit { VolumeUnit(rawValue: volumeUnitRaw) ?? .oz }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.ambientGradient(scheme).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        babyHeader
                        timerCard
                        quickAdd
                        summarySection
                        lastEvents
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showSwitcher = true } label: {
                        Image(systemName: "person.2.fill")
                    }
                    .accessibilityLabel("Switch baby")
                }
            }
            .sheet(item: $sheet) { which in
                switch which {
                case .feed(let preset, let seconds):
                    FeedEditorView(baby: baby, existing: nil, presetKind: preset, presetSeconds: seconds)
                case .diaper(let preset):
                    DiaperEditorView(baby: baby, existing: nil, presetKind: preset)
                case .sleep:
                    SleepEditorView(baby: baby, existing: nil)
                case .growth:
                    GrowthEditorView(baby: baby, existing: nil)
                }
            }
            .confirmationDialog("Switch baby", isPresented: $showSwitcher, titleVisibility: .visible) {
                ForEach(allBabies) { b in
                    Button(b.name) { activeBabyIDString = b.id.uuidString }
                }
            }
        }
    }

    // MARK: Header

    private var babyHeader: some View {
        Card {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: baby.colorHex)).frame(width: 52, height: 52)
                    Text(String(baby.name.prefix(1)).uppercased())
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(baby.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.primaryText(scheme))
                    Text(Fmt.age(birth: baby.birthDate) + " old")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText(scheme))
                }
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(baby.name), \(Fmt.age(birth: baby.birthDate)) old")
        }
    }

    // MARK: Timer card (breast + sleep)

    private var timerCard: some View {
        Card {
            VStack(spacing: 14) {
                // Live breast feed timer
                if let start = feedTimerStart {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        VStack(spacing: 10) {
                            Label("Feeding · \(feedTimerSide.label)", systemImage: "drop.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.apricot)
                            Text(Fmt.clock(ctx.date.timeIntervalSince(start)))
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.primaryText(scheme))
                                .accessibilityLabel("Feed timer \(Fmt.duration(ctx.date.timeIntervalSince(start)))")
                            HStack(spacing: 10) {
                                sidePicker
                            }
                            HStack(spacing: 12) {
                                Button(role: .destructive) { feedTimerStart = nil } label: {
                                    Text("Discard").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                Button {
                                    let elapsed = Int(Date().timeIntervalSince(start))
                                    feedTimerStart = nil
                                    Haptics.success(haptics)
                                    sheet = .feed(feedTimerSide, max(1, elapsed))
                                } label: {
                                    Text("Save feed").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.accent)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        Text("Start a breast feed")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.secondaryText(scheme))
                        HStack(spacing: 10) {
                            timerStartButton(.breastLeft, "L")
                            timerStartButton(.breastBoth, "Both")
                            timerStartButton(.breastRight, "R")
                        }
                    }
                }

                Divider()

                // Sleep toggle (start/stop)
                sleepRow
            }
        }
    }

    private var sidePicker: some View {
        Picker("Side", selection: $feedTimerSide) {
            Text("L").tag(FeedKind.breastLeft)
            Text("Both").tag(FeedKind.breastBoth)
            Text("R").tag(FeedKind.breastRight)
        }
        .pickerStyle(.segmented)
    }

    private func timerStartButton(_ side: FeedKind, _ title: String) -> some View {
        Button {
            feedTimerSide = side
            feedTimerStart = Date()
            Haptics.tap(haptics)
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.subtleFill(scheme), in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(Theme.accentDeep)
        }
        .accessibilityLabel("Start \(side.label) breast feed timer")
    }

    @ViewBuilder
    private var sleepRow: some View {
        if let ongoing = SprigEngine.ongoingSleep(for: baby) {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                HStack {
                    Label("Asleep", systemImage: "moon.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.sky)
                    Spacer()
                    Text(Fmt.clock(ctx.date.timeIntervalSince(ongoing.start)))
                        .font(.headline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.primaryText(scheme))
                    Button {
                        ongoing.end = Date()
                        try? context.save()
                        Haptics.success(haptics)
                    } label: {
                        Text("Wake").fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.sky)
                }
            }
        } else {
            Button {
                let log = SleepLog(start: Date())
                baby.sleeps.append(log)
                context.insert(log)
                try? context.save()
                Haptics.tap(haptics)
            } label: {
                HStack {
                    Label("Start sleep", systemImage: "moon.zzz.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.sky)
                    Spacer()
                    Image(systemName: "play.circle.fill").foregroundStyle(Theme.sky)
                }
            }
            .accessibilityLabel("Start a sleep session")
        }
    }

    // MARK: Quick add

    private var quickAdd: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Quick log", systemImage: "bolt.fill")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                quickButton("Bottle", "waterbottle.fill", Theme.apricot) { sheet = .feed(.bottle, nil) }
                quickButton("Diaper", "circle.grid.cross.fill", Theme.clay) { sheet = .diaper(nil) }
                quickButton("Sleep", "moon.fill", Theme.sky) { sheet = .sleep }
                quickButton("Growth", "ruler.fill", Theme.gold) { sheet = .growth }
            }
        }
    }

    private func quickButton(_ title: String, _ icon: String, _ tint: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection(haptics)
            action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.primaryText(scheme))
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(tint.opacity(0.8))
            }
            .padding(14)
            .background(Theme.card(scheme), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.hairline(scheme)))
        }
        .accessibilityLabel("Add \(title)")
    }

    // MARK: Summary

    private var summarySection: some View {
        let s = SprigEngine.summary(for: baby)
        return VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Today's summary", systemImage: "sun.max.fill")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                StatTile(icon: "drop.fill", value: "\(s.feedCount)", label: "Feeds", tint: Theme.apricot)
                StatTile(icon: "moon.fill", value: Fmt.duration(s.sleepSeconds), label: "Sleep", tint: Theme.sky)
                StatTile(icon: "circle.grid.cross.fill", value: "\(s.diaperCount)", label: "Diapers", tint: Theme.clay)
                StatTile(icon: "waterbottle.fill",
                         value: s.bottleML > 0 ? "\(Fmt.num(unit.display(fromML: s.bottleML))) \(unit.label)" : "—",
                         label: "Bottle total", tint: Theme.gold)
            }
        }
    }

    // MARK: Last events

    private var lastEvents: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Last events", systemImage: "clock.arrow.circlepath")
            Card {
                VStack(spacing: 12) {
                    lastRow(icon: "drop.fill", tint: Theme.apricot, title: "Feed",
                            value: SprigEngine.lastFeed(for: baby).map { Fmt.ago($0.date) })
                    Divider()
                    lastRow(icon: "moon.fill", tint: Theme.sky, title: "Sleep",
                            value: SprigEngine.lastSleep(for: baby).map { Fmt.ago($0.start) })
                    Divider()
                    lastRow(icon: "circle.grid.cross.fill", tint: Theme.clay, title: "Diaper",
                            value: SprigEngine.lastDiaper(for: baby).map { Fmt.ago($0.date) })
                }
            }
        }
    }

    private func lastRow(icon: String, tint: Color, title: String, value: String?) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 26)
                .accessibilityHidden(true)
            Text(title).foregroundStyle(Theme.primaryText(scheme))
            Spacer()
            Text(value ?? "No logs yet")
                .foregroundStyle(value == nil ? Theme.secondaryText(scheme) : Theme.accentDeep)
                .font(.subheadline.weight(.medium))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Last \(title): \(value ?? "no logs yet")")
    }
}

/// Identifies which add sheet to present from Today.
private enum TodaySheet: Identifiable {
    case feed(FeedKind?, Int?)
    case diaper(DiaperKind?)
    case sleep
    case growth

    var id: String {
        switch self {
        case .feed(let k, let s): return "feed-\(k?.rawValue ?? "")-\(s ?? 0)"
        case .diaper(let k): return "diaper-\(k?.rawValue ?? "")"
        case .sleep: return "sleep"
        case .growth: return "growth"
        }
    }
}
