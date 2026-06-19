import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \HikeSession.date) private var sessions: [HikeSession]
    @Query(sort: \Trail.name) private var trails: [Trail]
    @AppStorage(TrekSettings.distanceUnit) private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage(TrekSettings.elevationUnit) private var elevationUnitRaw = ElevationUnit.meters.rawValue
    @State private var engine = HikeEngine()
    @State private var selectedChart: ChartType = .weeklyDistance

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }
    private var elevationUnit: ElevationUnit { ElevationUnit(rawValue: elevationUnitRaw) ?? .meters }

    enum ChartType: String, CaseIterable {
        case weeklyDistance = "Distance"
        case monthlyElevation = "Elevation"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if sessions.isEmpty {
                        emptyState
                    } else {
                        summaryCards
                        chartSection
                        trailLeaderboard
                        difficultyBreakdown
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Data Yet", systemImage: "chart.bar.xaxis")
        } description: {
            Text("Log your first hike to see stats and charts.")
        }
    }

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatPill(
                    icon: "figure.hiking",
                    value: "\(sessions.count)",
                    label: "Total Hikes",
                    color: TrekTheme.forestGreen
                )
                StatPill(
                    icon: "arrow.left.and.right",
                    value: String(format: "%.0f", engine.totalDistanceKm(sessions)),
                    label: "km total",
                    color: TrekTheme.skyBlue
                )
            }
            HStack(spacing: 12) {
                StatPill(
                    icon: "arrow.up.circle",
                    value: String(format: "%.0f", engine.totalElevationM(sessions)),
                    label: "m elevation",
                    color: TrekTheme.trailBrown
                )
                StatPill(
                    icon: "clock.fill",
                    value: String(format: "%.0f", engine.totalHours(sessions)),
                    label: "hours",
                    color: TrekTheme.stoneGray
                )
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Chart", selection: $selectedChart) {
                ForEach(ChartType.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)

            switch selectedChart {
            case .weeklyDistance:
                weeklyDistanceChart
            case .monthlyElevation:
                monthlyElevationChart
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var weeklyDistanceChart: some View {
        let data = engine.weeklyDistances(sessions)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Distance (km)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Chart(data, id: \.week) { item in
                BarMark(x: .value("Week", item.week), y: .value("km", item.km))
                    .foregroundStyle(TrekTheme.forestGreen.gradient)
                    .cornerRadius(4)
            }
            .frame(height: 160)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .accessibilityLabel("Weekly distance bar chart")
    }

    private var monthlyElevationChart: some View {
        let data = engine.monthlyElevations(sessions)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Monthly Elevation Gain (m)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Chart(data, id: \.month) { item in
                BarMark(x: .value("Month", item.month), y: .value("m", item.m))
                    .foregroundStyle(TrekTheme.trailBrown.gradient)
                    .cornerRadius(4)
            }
            .frame(height: 160)
        }
        .accessibilityLabel("Monthly elevation gain bar chart")
    }

    private var trailLeaderboard: some View {
        let sorted = trails.filter { !$0.sessions.isEmpty }
            .sorted { $0.sessionCount > $1.sessionCount }
            .prefix(5)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Most Visited Trails")
                .font(.headline)
                .padding(.leading, 4)

            ForEach(Array(sorted.enumerated()), id: \.element.id) { idx, trail in
                HStack(spacing: 12) {
                    Text("\(idx + 1)")
                        .font(.caption.weight(.bold))
                        .frame(width: 20)
                        .foregroundStyle(.secondary)
                    Text(trail.name)
                        .font(.subheadline)
                    Spacer()
                    Text("\(trail.sessionCount) hikes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var difficultyBreakdown: some View {
        let counts = Dictionary(grouping: sessions) { $0.trail?.difficulty ?? .moderate }
        let sorted: [TrailDifficulty] = [.easy, .moderate, .hard, .expert]

        return VStack(alignment: .leading, spacing: 12) {
            Text("By Difficulty")
                .font(.headline)
                .padding(.leading, 4)

            Chart {
                ForEach(sorted, id: \.self) { diff in
                    BarMark(
                        x: .value("Difficulty", diff.rawValue),
                        y: .value("Hikes", counts[diff]?.count ?? 0)
                    )
                    .foregroundStyle(TrekTheme.difficultyColor(diff).gradient)
                    .cornerRadius(6)
                }
            }
            .frame(height: 140)
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel("Difficulty breakdown bar chart")
        }
    }
}
