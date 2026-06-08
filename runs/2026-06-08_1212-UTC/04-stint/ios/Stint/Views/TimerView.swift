import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TimeEntry.start, order: .reverse) private var entries: [TimeEntry]
    @Query(filter: #Predicate<Project> { !$0.archived }, sort: \Project.name) private var projects: [Project]
    @AppStorage("defaultCurrency") private var currency = Locale.current.currency?.identifier ?? "USD"

    @State private var detail = ""
    @State private var selectedProject: Project?
    @State private var showSettings = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let engine = TimeEngine()
    private var running: TimeEntry? { engine.running(entries) }
    private var todayEntries: [TimeEntry] { engine.entries(entries, on: .now) }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                ScrollView {
                    VStack(spacing: 18) {
                        timerCard
                        if running == nil { startControls }
                        todayCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Timer")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var timerCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            VStack(spacing: 12) {
                if let running {
                    HStack(spacing: 6) {
                        StatusDot()
                        Text(running.project?.name ?? "No project")
                            .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text2)
                    }
                    Text(DurationFormat.clock(running.seconds(now: now)))
                        .font(.system(size: 52, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Brand.text)
                        .contentTransition(.numericText())
                        .accessibilityLabel("Elapsed \(DurationFormat.compact(running.seconds(now: now)))")
                    if !running.detail.isEmpty {
                        Text(running.detail).font(.subheadline).foregroundStyle(Brand.text3)
                    }
                    if let p = running.project, p.billable, p.effectiveRate > 0 {
                        Text(Money.string(running.earnings(now: now), code: currency))
                            .font(Brand.mono(14, weight: .medium)).foregroundStyle(Brand.live)
                    }
                    Button {
                        stop(running)
                    } label: { Label("Stop", systemImage: "stop.fill") }
                        .buttonStyle(InkButtonStyle())
                        .padding(.top, 4)
                } else {
                    Text("0:00:00")
                        .font(.system(size: 52, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Brand.text3)
                    Text("Ready when you are")
                        .font(.subheadline).foregroundStyle(Brand.text3)
                }
            }
            .frame(maxWidth: .infinity)
            .glassCard(padding: 22)
        }
    }

    private var startControls: some View {
        VStack(spacing: 12) {
            TextField("What are you working on?", text: $detail)
                .textFieldStyle(.roundedBorder)
            Menu {
                Button("No project") { selectedProject = nil }
                ForEach(projects) { p in
                    Button { selectedProject = p } label: { Label(p.name, systemImage: "circle.fill") }
                }
            } label: {
                HStack {
                    Circle().fill(Color(hex: selectedProject?.colorHex ?? 0x8B8FA3)).frame(width: 10, height: 10)
                    Text(selectedProject?.name ?? "No project").foregroundStyle(Brand.text)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(Brand.text3)
                }
                .padding(.vertical, 12).padding(.horizontal, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            Button {
                start()
            } label: { Label("Start", systemImage: "play.fill") }
                .buttonStyle(InkButtonStyle())
        }
        .glassCard()
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today").font(.headline).foregroundStyle(Brand.text)
                Spacer()
                Text(DurationFormat.compact(engine.totalSeconds(todayEntries)))
                    .font(Brand.mono(14, weight: .medium)).foregroundStyle(Color.accentColor)
            }
            if todayEntries.isEmpty {
                Text("No time tracked today yet.")
                    .font(.subheadline).foregroundStyle(Brand.text3)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 10)
            } else {
                ForEach(todayEntries) { e in EntryRow(entry: e, currency: currency) }
            }
        }
        .glassCard()
    }

    private func start() {
        // Only one timer at a time: stop any running entry first.
        if let r = running { stop(r) }
        let entry = TimeEntry(detail: detail.trimmingCharacters(in: .whitespaces),
                              start: .now, end: nil, project: selectedProject)
        context.insert(entry)
        detail = ""
        Haptics.success()
    }

    private func stop(_ entry: TimeEntry) {
        entry.end = .now
        try? context.save()
        Haptics.tap()
    }
}

struct EntryRow: View {
    let entry: TimeEntry
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(Color(hex: entry.project?.colorHex ?? 0x8B8FA3)).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.detail.isEmpty ? (entry.project?.name ?? "Untitled") : entry.detail)
                    .font(.subheadline.weight(.medium)).foregroundStyle(Brand.text).lineLimit(1)
                Text("\(Format.shortTime.string(from: entry.start))\(entry.end.map { " – " + Format.shortTime.string(from: $0) } ?? " – running")")
                    .font(.caption).foregroundStyle(Brand.text3)
            }
            Spacer()
            Text(DurationFormat.compact(entry.seconds()))
                .font(Brand.mono(13, weight: .medium)).foregroundStyle(Brand.text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.detail), \(DurationFormat.compact(entry.seconds()))")
    }
}
