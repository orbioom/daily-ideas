import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \SwimSession.date, order: .reverse) private var sessions: [SwimSession]
    @Query private var settingsAll: [SplashSettings]
    @Environment(\.modelContext) private var context
    @State private var showingLog = false

    var useYards: Bool { settingsAll.first?.useYards ?? false }

    var grouped: [(String, [SwimSession])] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        let groups = Dictionary(grouping: sessions) { session -> String in
            fmt.string(from: session.date)
        }
        return groups.sorted { a, b in
            let da = fmt.date(from: a.key) ?? .distantPast
            let db = fmt.date(from: b.key) ?? .distantPast
            return da > db
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView {
                        Label("No Sessions Yet", systemImage: "figure.pool.swim")
                    } description: {
                        Text("Tap + to log your first swim session.")
                    } actions: {
                        Button("Log Session") { showingLog = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(grouped, id: \.0) { month, monthSessions in
                            Section {
                                ForEach(monthSessions) { session in
                                    NavigationLink {
                                        SessionDetailView(session: session)
                                    } label: {
                                        SessionRow(session: session, useYards: useYards)
                                    }
                                }
                                .onDelete { offsets in
                                    for i in offsets { context.delete(monthSessions[i]) }
                                    try? context.save()
                                }
                            } header: {
                                HStack {
                                    Text(month)
                                    Spacer()
                                    let total = monthSessions.reduce(0.0) { $0 + ($1.computedDistance > 0 ? $1.computedDistance : $1.totalDistanceMeters) }
                                    Text(metersToDisplay(total, useYards: useYards))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLog = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Log swim session")
                }
            }
            .sheet(isPresented: $showingLog) {
                LogSessionView()
            }
        }
    }
}

struct SessionRow: View {
    let session: SwimSession
    let useYards: Bool

    var dist: Double {
        session.computedDistance > 0 ? session.computedDistance : session.totalDistanceMeters
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(SplashTheme.accent.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "figure.pool.swim")
                    .foregroundStyle(SplashTheme.accent)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.date, style: .date)
                        .font(.subheadline.bold())
                    Spacer()
                    Text(metersToDisplay(dist, useYards: useYards))
                        .font(.subheadline.bold())
                        .foregroundStyle(SplashTheme.accent)
                }
                HStack(spacing: 8) {
                    if let pool = session.pool {
                        Text(pool.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Label(formatDuration(session.durationSeconds), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    RatingStars(rating: session.feelRating)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Session on \(session.date.formatted(date: .long, time: .omitted)). Distance: \(metersToDisplay(dist, useYards: useYards)). Duration: \(formatDuration(session.durationSeconds)). Feel: \(session.feelRating) out of 5.")
    }
}
