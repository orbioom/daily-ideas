import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \HikeSession.date, order: .reverse) private var sessions: [HikeSession]
    @Query(sort: \Trail.name) private var trails: [Trail]
    @AppStorage(TrekSettings.distanceUnit) private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage(TrekSettings.elevationUnit) private var elevationUnitRaw = ElevationUnit.meters.rawValue
    @State private var showLogSheet = false
    @State private var engine = HikeEngine()

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }
    private var elevationUnit: ElevationUnit { ElevationUnit(rawValue: elevationUnitRaw) ?? .meters }
    private var recentSessions: [HikeSession] { Array(sessions.prefix(5)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerCard
                    statsRow
                    if recentSessions.isEmpty {
                        emptyRecentState
                    } else {
                        recentHikesSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Trek")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel("Log a hike")
                    }
                }
            }
            .sheet(isPresented: $showLogSheet) {
                LogHikeView(trails: trails)
            }
        }
    }

    private var headerCard: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [TrekTheme.forestGreen, Color(red: 0.12, green: 0.44, blue: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 20))

            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back!")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Ready for the next trail?")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
            .padding(20)

            Image(systemName: "mountain.2.fill")
                .font(.system(size: 80))
                .foregroundStyle(.white.opacity(0.12))
                .offset(x: 240, y: -20)
                .accessibilityHidden(true)
        }
    }

    private var statsRow: some View {
        let monthSessions = engine.sessionsThisMonth(sessions)
        let totalDist = engine.totalDistanceKm(sessions)
        let monthDist = engine.totalDistanceKm(monthSessions)
        let totalElev = engine.totalElevationM(sessions)

        return HStack(spacing: 12) {
            StatPill(
                icon: "figure.hiking",
                value: "\(sessions.count)",
                label: "Hikes",
                color: TrekTheme.forestGreen
            )
            StatPill(
                icon: "arrow.left.and.right",
                value: distanceUnit.label(totalDist).components(separatedBy: " ").first ?? "0",
                label: "Total \(distanceUnit.shortLabel)",
                color: TrekTheme.skyBlue
            )
            StatPill(
                icon: "arrow.up.circle",
                value: elevationUnit.label(totalElev).components(separatedBy: " ").first ?? "0",
                label: "Total \(elevationUnit.shortLabel)",
                color: TrekTheme.trailBrown
            )
        }
    }

    private var emptyRecentState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.hiking")
                .font(.system(size: 48))
                .foregroundStyle(TrekTheme.forestGreen)
                .accessibilityHidden(true)
            Text("No Hikes Yet")
                .font(.title3.bold())
            Text("Tap + to log your first hike and start building your trail history.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .trekCard()
    }

    private var recentHikesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Hikes")
                .font(.title3.bold())
                .padding(.leading, 4)

            ForEach(recentSessions) { session in
                NavigationLink(destination: SessionDetailView(session: session)) {
                    HikeSessionRow(session: session, distanceUnit: distanceUnit)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct HikeSessionRow: View {
    let session: HikeSession
    let distanceUnit: DistanceUnit

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(TrekTheme.forestGreen.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "figure.hiking")
                    .foregroundStyle(TrekTheme.forestGreen)
                    .font(.system(size: 20))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.trail?.name ?? "Quick Hike")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(distanceUnit.label(session.distanceKm))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(session.durationFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.trail?.name ?? "Quick Hike"), \(session.date.formatted(date: .abbreviated, time: .omitted)), \(distanceUnit.label(session.distanceKm)), \(session.durationFormatted)")
    }
}
