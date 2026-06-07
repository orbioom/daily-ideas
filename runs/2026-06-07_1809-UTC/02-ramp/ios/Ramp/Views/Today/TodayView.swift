import SwiftUI
import SwiftData
import Charts

/// The dashboard: today's Fitness / Fatigue / Form, ramp rate, a mini PMC,
/// recent rides, and the focal "Log ride" action.
struct TodayView: View {
    @Query(sort: \Ride.date, order: .reverse) private var rides: [Ride]

    @State private var showLog = false
    @State private var isComputing = false
    @State private var snapshot = LoadEngine.Snapshot()
    @State private var series: [LoadEngine.DayPoint] = []

    private var status: LoadEngine.FormStatus { LoadEngine.formStatus(tsb: snapshot.form) }
    private var miniSeries: [LoadEngine.DayPoint] { Array(series.suffix(90)) }
    private var recent: [Ride] { Array(rides.prefix(5)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                if rides.isEmpty {
                    emptyState
                } else if isComputing {
                    loadingState
                } else {
                    content
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Today")
            .background(Brand.pageBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.tap(); showLog = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Log a ride")
                }
            }
            .sheet(isPresented: $showLog) {
                RideEditView(ride: nil)
            }
        }
        .task(id: rideSignature) { await recompute() }
    }

    /// Changes whenever rides are added, removed, or edited so the chart recomputes.
    private var rideSignature: Int {
        var hasher = Hasher()
        hasher.combine(rides.count)
        for r in rides {
            hasher.combine(r.id)
            hasher.combine(r.durationMin)
            hasher.combine(r.normalizedPower)
            hasher.combine(r.tssManual)
            hasher.combine(r.ftpAtTime)
            hasher.combine(r.entryRaw)
            hasher.combine(r.date)
        }
        return hasher.finalize()
    }

    // MARK: Content

    private var content: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            statRow
            formCard
            if miniSeries.count > 1 { pmcCard }
            recentCard
            logButton
        }
        .padding(20)
        .animation(Brand.ease(), value: snapshot.hasData)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Eyebrow(text: Format.dayMonth.string(from: Date()))
            Text("Your form today")
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.text)
        }
    }

    private var statRow: some View {
        HStack(spacing: 12) {
            StatTile(value: Format.int(snapshot.fitness), label: "Fitness · CTL", accent: Brand.live)
            StatTile(value: Format.int(snapshot.fatigue), label: "Fatigue · ATL", accent: Brand.warn)
            StatTile(value: Format.signedInt(snapshot.form), label: "Form · TSB", accent: status.color)
        }
    }

    private var formCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    StatusDot(color: status.color)
                    Text(status.label)
                        .font(.headline)
                        .foregroundStyle(Brand.text)
                }
                InfoRow(label: "7-day ramp rate",
                        value: "\(Format.signedInt(snapshot.rampRate)) CTL", mono: true)
                InfoRow(label: "Logged rides", value: "\(rides.count)", mono: true)
                Text(rampGuidance)
                    .font(.subheadline)
                    .foregroundStyle(Brand.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Form status: \(status.label). Ramp rate \(Format.signedInt(snapshot.rampRate)) CTL over seven days.")
    }

    private var rampGuidance: String {
        switch snapshot.rampRate {
        case let x where x > 8:  return "You're ramping hard. Watch fatigue and plan recovery soon."
        case let x where x > 2:  return "Healthy, sustainable build. Keep the consistency going."
        case (-2)...2:           return "Holding steady. A good place to maintain or push."
        default:                 return "Fitness is easing back — useful for a taper or recovery block."
        }
    }

    private var pmcCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(text: "Last 90 days")
                PMCChart(points: miniSeries, showTSB: true, height: 170)
                LegendRow()
            }
        }
    }

    private var recentCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    SectionTitle(text: "Recent rides")
                    Spacer()
                    Text("\(rides.count) total")
                        .font(Brand.mono(11, weight: .medium))
                        .foregroundStyle(Brand.text3)
                }
                ForEach(recent) { ride in
                    NavigationLink {
                        RideEditView(ride: ride)
                    } label: {
                        RideRow(ride: ride)
                    }
                    .buttonStyle(.plain)
                    if ride.id != recent.last?.id {
                        Divider().overlay(Brand.hairline)
                    }
                }
            }
        }
    }

    private var logButton: some View {
        Button {
            Haptics.tap(); showLog = true
        } label: {
            Label("Log ride", systemImage: "plus.circle.fill")
        }
        .buttonStyle(InkButtonStyle())
        .padding(.top, 4)
    }

    // MARK: States

    private var emptyState: some View {
        VStack(spacing: 20) {
            EmptyStateView(icon: "figure.outdoor.cycle",
                           title: "No rides yet",
                           message: "Log your first ride and Ramp will start charting your fitness, fatigue and form.")
            Button { Haptics.tap(); showLog = true } label: {
                Label("Log your first ride", systemImage: "plus.circle.fill")
            }
            .buttonStyle(InkButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.top, 60)
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Crunching your training load…")
                .font(.subheadline)
                .foregroundStyle(Brand.text2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 120)
    }

    // MARK: Compute

    @MainActor
    private func recompute() async {
        isComputing = true
        // Snapshot model values into plain structs off the main store, compute, then publish.
        let inputs = rides.map { RideInput(date: $0.date, tss: $0.tss,
                                           np: $0.normalizedPower, ftp: $0.ftpAtTime,
                                           durationMin: $0.durationMin, entryPower: $0.entry == .power) }
        let computed = await Task.detached(priority: .userInitiated) { () -> (LoadEngine.Snapshot, [LoadEngine.DayPoint]) in
            let proxies = inputs.map { $0.proxyRide() }
            let snap = LoadEngine.snapshot(rides: proxies)
            let pts = LoadEngine.series(rides: proxies)
            return (snap, pts)
        }.value
        snapshot = computed.0
        series = computed.1
        isComputing = false
    }
}

/// Lightweight transferable copy of a ride for off-main computation.
struct RideInput {
    let date: Date
    let tss: Double
    let np: Int
    let ftp: Int
    let durationMin: Int
    let entryPower: Bool

    /// Build a detached Ride instance (not inserted in any context) for the engine.
    func proxyRide() -> Ride {
        Ride(date: date, durationMin: durationMin,
             entry: entryPower ? .power : .manual,
             normalizedPower: np, ftpAtTime: ftp,
             tssManual: entryPower ? 0 : tss)
    }
}

/// One compact ride row used across screens.
struct RideRow: View {
    let ride: Ride
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: ride.type.symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Brand.text2)
                .frame(width: 26)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(ride.name.isEmpty ? ride.type.label : ride.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.text)
                    .lineLimit(1)
                Text("\(ride.type.label) · \(Format.duration(ride.durationMin))")
                    .font(.caption)
                    .foregroundStyle(Brand.text3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Format.int(ride.tss))
                    .font(Brand.mono(16, weight: .semibold))
                    .foregroundStyle(Brand.text)
                Text("TSS").font(Brand.mono(9, weight: .medium)).foregroundStyle(Brand.text3)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(ride.name.isEmpty ? ride.type.label : ride.name), \(ride.type.label), \(Format.duration(ride.durationMin)), \(Format.int(ride.tss)) TSS")
    }
}
