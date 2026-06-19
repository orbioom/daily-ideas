import SwiftUI
import SwiftData

struct TrailDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var trail: Trail
    @AppStorage(TrekSettings.distanceUnit) private var distanceUnitRaw = DistanceUnit.km.rawValue
    @AppStorage(TrekSettings.elevationUnit) private var elevationUnitRaw = ElevationUnit.meters.rawValue
    @State private var showLogSheet = false
    @State private var sessionToDelete: HikeSession? = nil
    @State private var showDeleteAlert = false

    private var distanceUnit: DistanceUnit { DistanceUnit(rawValue: distanceUnitRaw) ?? .km }
    private var elevationUnit: ElevationUnit { ElevationUnit(rawValue: elevationUnitRaw) ?? .meters }

    private var sortedSessions: [HikeSession] {
        trail.sessions.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section {
                trailHeader
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)

            Section("Stats") {
                statsGrid
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.init())

            if !trail.trailDescription.isEmpty {
                Section("About") {
                    Text(trail.trailDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                if sortedSessions.isEmpty {
                    ContentUnavailableView {
                        Label("No Hikes Yet", systemImage: "figure.hiking")
                    } description: {
                        Text("Log a hike on this trail to start tracking your progress.")
                    } actions: {
                        Button("Log Hike") { showLogSheet = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(sortedSessions) { session in
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            SessionRow(session: session, distanceUnit: distanceUnit)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                sessionToDelete = session
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Hike History")
                    Spacer()
                    Button("Log Hike") { showLogSheet = true }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TrekTheme.forestGreen)
                }
            }
        }
        .navigationTitle(trail.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    trail.isFavorite.toggle()
                } label: {
                    Image(systemName: trail.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(trail.isFavorite ? TrekTheme.sunGold : .primary)
                }
                .accessibilityLabel(trail.isFavorite ? "Remove from favorites" : "Add to favorites")
            }
        }
        .sheet(isPresented: $showLogSheet) {
            LogHikeView(preselectedTrail: trail, trails: [trail])
        }
        .alert("Delete Hike?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let s = sessionToDelete {
                    context.delete(s)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This hike log will be permanently deleted.")
        }
    }

    private var trailHeader: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [TrekTheme.difficultyColor(trail.difficulty).opacity(0.8),
                         TrekTheme.difficultyColor(trail.difficulty)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(height: 140)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    DifficultyBadge(difficulty: trail.difficulty)
                        .colorScheme(.dark)
                    if trail.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(TrekTheme.sunGold)
                            .accessibilityHidden(true)
                    }
                }
                if !trail.location.isEmpty {
                    Label(trail.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding(16)
        }
    }

    private var statsGrid: some View {
        let engine = HikeEngine()
        let sessions = trail.sessions
        return HStack(spacing: 10) {
            StatPill(icon: "figure.hiking", value: "\(sessions.count)", label: "Hikes")
            StatPill(
                icon: "arrow.left.and.right",
                value: String(format: "%.1f", engine.totalDistanceKm(sessions)),
                label: "km total",
                color: TrekTheme.skyBlue
            )
            StatPill(
                icon: "arrow.up.circle",
                value: String(format: "%.0f", engine.totalElevationM(sessions)),
                label: "m gain",
                color: TrekTheme.trailBrown
            )
        }
        .padding(.horizontal)
    }
}

struct SessionRow: View {
    let session: HikeSession
    let distanceUnit: DistanceUnit

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 8) {
                    Text(distanceUnit.label(session.distanceKm))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(session.durationFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if session.rating > 0 {
                StarRatingView(rating: session.rating)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(session.date.formatted(date: .abbreviated, time: .omitted)), \(distanceUnit.label(session.distanceKm)), \(session.durationFormatted)\(session.rating > 0 ? ", \(session.rating) stars" : "")"
        )
    }
}
