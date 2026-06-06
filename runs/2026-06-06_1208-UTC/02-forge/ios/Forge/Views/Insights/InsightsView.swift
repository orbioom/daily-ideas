import SwiftUI
import SwiftData

/// Training overview: totals, volume by group, and a link to the plate tool.
struct InsightsView: View {
    @Query private var workouts: [Workout]
    @Query private var sets: [SetEntry]
    @AppStorage("weightUnit") private var unitRaw = WeightUnit.kg.rawValue

    private var unit: WeightUnit { WeightUnit(rawValue: unitRaw) ?? .kg }

    private var totalVolume: Double { workouts.reduce(0) { $0 + $1.volumeKg } }
    private var weeklyAverage: Double {
        guard let first = workouts.map(\.date).min() else { return 0 }
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: first, to: Date()).weekOfYear ?? 1)
        return Double(workouts.count) / Double(weeks)
    }
    private var volumeByGroup: [(MuscleGroup, Double)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        var dict: [MuscleGroup: Double] = [:]
        for s in sets where !s.isWarmup {
            guard let g = s.exercise?.group, let date = s.workout?.date, date >= cutoff else { continue }
            dict[g, default: 0] += s.volumeKg
        }
        return dict.sorted { $0.value > $1.value }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.pageBackground
                Group {
                    if workouts.isEmpty {
                        EmptyStateView(icon: "chart.line.uptrend.xyaxis",
                                       title: "No insights yet",
                                       message: "Log a few sessions and your trends will appear here.")
                    } else { content }
                }
            }
            .navigationTitle("Insights")
            .navigationDestination(for: String.self) { _ in PlateCalcView() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    StatTile(value: "\(workouts.count)", label: "Sessions")
                    StatTile(value: Fmt.volume(totalVolume, unit: unit), label: "Total volume", tint: Brand.live)
                    StatTile(value: String(format: "%.1f", weeklyAverage), label: "Per week")
                }
                groupCard
                NavigationLink(value: "plates") {
                    HStack(spacing: 14) {
                        Image(systemName: "dumbbell").font(.title2).foregroundStyle(Brand.text)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Plate calculator").font(.headline).foregroundStyle(Brand.text)
                            Text("What to load on each side of the bar").font(.subheadline).foregroundStyle(Brand.text2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.footnote).foregroundStyle(Brand.text3)
                    }
                    .glassCard()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16).padding(.bottom, 28)
        }
    }

    private var groupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Volume by group · last 30 days")
            if volumeByGroup.isEmpty {
                Text("No working sets in the last 30 days.").font(.subheadline).foregroundStyle(Brand.text2)
            } else {
                let maxV = volumeByGroup.first?.value ?? 1
                ForEach(volumeByGroup, id: \.0) { g, v in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(g.label, systemImage: g.symbol).font(.subheadline).foregroundStyle(Brand.text)
                            Spacer()
                            Text(Fmt.volume(v, unit: unit)).font(Brand.mono(13)).foregroundStyle(Brand.text2)
                        }
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Brand.live.opacity(0.8))
                                .frame(width: max(6, geo.size.width * (maxV > 0 ? v / maxV : 0)), height: 8)
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .glassCard()
    }
}
