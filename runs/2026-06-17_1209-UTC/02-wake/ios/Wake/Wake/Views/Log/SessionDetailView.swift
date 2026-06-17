import SwiftUI
import SwiftData

/// Detail of one completed session: totals, per-set splits, pace, and SWOLF.
struct SessionDetailView: View {
    @Bindable var session: SwimSession

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage(PrefKey.unitsRaw) private var unitsRaw = DistanceUnit.meters.rawValue
    @AppStorage(PrefKey.isPro) private var isPro = false
    @AppStorage(PrefKey.bodyWeightKg) private var bodyWeightKg = 72.0

    @State private var paywallReason: PaywallReason?

    private var unit: DistanceUnit { DistanceUnit(rawValue: unitsRaw) ?? .meters }
    private var fmt: UnitFormatter { UnitFormatter(unit: unit) }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    summary
                    if !session.notes.isEmpty {
                        SectionCard(title: "Notes", symbol: "text.quote") {
                            Text(session.notes)
                                .font(.callout)
                                .foregroundStyle(Theme.inkSoft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    splitsCard
                }
                .padding(20)
            }
        }
        .navigationTitle(session.workoutName ?? "Free swim")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $paywallReason) { reason in
            PaywallView(reason: reason)
        }
    }

    private var avgPace: Double? {
        SwimMath.pacePer100(seconds: Double(session.durationSeconds),
                            distanceMeters: session.totalDistanceMeters)
    }

    private var summary: some View {
        VStack(spacing: 12) {
            Text(session.date, format: .dateTime.weekday(.wide).month().day().hour().minute())
                .font(.subheadline)
                .foregroundStyle(Theme.inkSoft)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatTile(title: "Distance", value: fmt.distance(session.totalDistanceMeters), symbol: "ruler")
                StatTile(title: "Duration", value: UnitFormatter.clock(Double(session.durationSeconds)), symbol: "clock")
                StatTile(title: "Avg pace",
                         value: avgPace.map { fmt.pacePer100($0) } ?? "—",
                         symbol: "speedometer")
                StatTile(title: "Calories",
                         value: "\(Int(SwimMath.sessionCalories(sets: session.orderedSets, weightKg: bodyWeightKg))) kcal",
                         symbol: "flame.fill",
                         tint: Theme.warn)
            }
        }
    }

    private var splitsCard: some View {
        SectionCard(title: "Splits", symbol: "list.number") {
            if session.orderedSets.isEmpty {
                Text("No individual sets were recorded for this swim.")
                    .font(.footnote)
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(session.orderedSets.enumerated()), id: \.element.id) { index, set in
                        SplitRow(index: index + 1,
                                 set: set,
                                 poolLength: session.poolLengthMeters,
                                 unit: unit,
                                 showSwolf: isPro)
                        if index < session.orderedSets.count - 1 {
                            LaneDivider()
                        }
                    }
                    if !isPro {
                        Button {
                            paywallReason = .stats
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                Text("Unlock SWOLF analysis with Pro")
                            }
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.accent)
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
    }
}

/// One split row with computed pace and optional SWOLF.
struct SplitRow: View {
    let index: Int
    let set: CompletedSet
    let poolLength: Double
    let unit: DistanceUnit
    let showSwolf: Bool

    private var fmt: UnitFormatter { UnitFormatter(unit: unit) }

    private var pace: Double? {
        SwimMath.pacePer100(seconds: set.actualTimeSeconds, distanceMeters: set.totalDistanceMeters)
    }

    private var swolf: Double? {
        guard showSwolf else { return nil }
        return SwimMath.swolf(totalSeconds: set.actualTimeSeconds,
                              distanceMeters: set.totalDistanceMeters,
                              poolLengthMeters: poolLength,
                              strokesPerLength: set.strokeCountPerLength)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(index). \(set.repeats) × \(Int(unit.value(fromMeters: set.distancePerRepMeters))) \(unit.shortUnit)")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.ink)
                StrokeBadge(stroke: set.stroke)
                Spacer()
                Text(UnitFormatter.clock(set.actualTimeSeconds))
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(Theme.accent)
                    .monospacedDigit()
            }
            HStack(spacing: 8) {
                if let pace {
                    Pill(text: fmt.pacePer100(pace), color: Theme.accentDeep)
                }
                if let swolf {
                    Pill(text: "SWOLF \(Int(swolf.rounded()))", color: Theme.good)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
